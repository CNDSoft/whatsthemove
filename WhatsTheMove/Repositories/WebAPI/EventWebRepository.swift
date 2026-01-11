//
//  EventWebRepository.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit 

protocol EventWebRepository {
    func createEvent(_ event: Event) async throws
    func getEvent(id: String) async throws -> Event?
    func getEvents(forUserId userId: String) async throws -> [Event]
    func updateEvent(_ event: Event) async throws
    func deleteEvent(id: String) async throws
    func uploadEventImage(_ image: UIImage, userId: String, eventId: String) async throws -> String
    func deleteEventImage(userId: String, eventId: String) async throws
}

struct RealEventWebRepository: EventWebRepository {
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let collectionName = "events"
    
    func createEvent(_ event: Event) async throws {
        print("RealEventWebRepository - Creating event: \(event.id)")
        
        try await db.collection(collectionName)
            .document(event.id)
            .setData(event.toDictionary())
        
        print("RealEventWebRepository - Event created successfully")
    }
    
    func getEvent(id: String) async throws -> Event? {
        print("RealEventWebRepository - Getting event: \(id)")
        
        let document = try await db.collection(collectionName)
            .document(id)
            .getDocument()
        
        guard document.exists, let data = document.data() else {
            print("RealEventWebRepository - Event not found")
            return nil
        }
        
        let event = Event.fromDictionary(data, id: id)
        print("RealEventWebRepository - Event retrieved: \(event?.name ?? "nil")")
        return event
    }
    
    func getEvents(forUserId userId: String) async throws -> [Event] {
        print("RealEventWebRepository - Getting events for user: \(userId)")
        
        let snapshot = try await db.collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let events = snapshot.documents.compactMap { document -> Event? in
            Event.fromDictionary(document.data(), id: document.documentID)
        }.sorted { $0.eventDate < $1.eventDate }
        
        print("RealEventWebRepository - Retrieved \(events.count) events for user")
        return events
    }
    
    func updateEvent(_ event: Event) async throws {
        print("RealEventWebRepository - Updating event: \(event.id)")
        
        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        
        try await db.collection(collectionName)
            .document(event.id)
            .updateData(updatedEvent.toDictionary(forUpdate: true))
        
        print("RealEventWebRepository - Event updated successfully")
    }
    
    func deleteEvent(id: String) async throws {
        print("RealEventWebRepository - Deleting event: \(id)")
        
        try await db.collection(collectionName)
            .document(id)
            .delete()
        
        print("RealEventWebRepository - Event deleted successfully")
    }
    
    func uploadEventImage(_ image: UIImage, userId: String, eventId: String) async throws -> String {
        print("RealEventWebRepository - Uploading image for event: \(eventId)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw EventRepositoryError.imageCompressionFailed
        }
        
        let storageRef = storage.reference()
        let imagePath = "event_images/\(userId)/\(eventId).jpg"
        let imageRef = storageRef.child(imagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        return try await withCheckedThrowingContinuation { continuation in
            imageRef.putData(imageData, metadata: metadata) { _, error in
                if let error = error {
                    print("RealEventWebRepository - Upload failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("RealEventWebRepository - Failed to get download URL: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let downloadURL = url else {
                        print("RealEventWebRepository - Download URL is nil")
                        continuation.resume(throwing: EventRepositoryError.imageUploadFailed)
                        return
                    }
                    
                    print("RealEventWebRepository - Image uploaded successfully: \(downloadURL.absoluteString)")
                    continuation.resume(returning: downloadURL.absoluteString)
                }
            }
        }
    }
    
    func deleteEventImage(userId: String, eventId: String) async throws {
        print("RealEventWebRepository - Deleting image for event: \(eventId)")
        
        let storageRef = storage.reference()
        let imagePath = "event_images/\(userId)/\(eventId).jpg"
        let imageRef = storageRef.child(imagePath)
        
        do {
            try await imageRef.delete()
            print("RealEventWebRepository - Image deleted successfully")
        } catch {
            print("RealEventWebRepository - Image deletion failed or image not found: \(error.localizedDescription)")
        }
    }
}

// MARK: - EventRepositoryError

enum EventRepositoryError: LocalizedError {
    case imageCompressionFailed
    case imageUploadFailed
    case eventNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .imageUploadFailed:
            return "Failed to upload event image"
        case .eventNotFound:
            return "Event not found"
        case .invalidData:
            return "Invalid event data"
        }
    }
}

// MARK: - Event Dictionary Conversion

extension Event {
    
    func toDictionary(forUpdate: Bool = false) -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "name": name,
            "eventDate": Timestamp(date: eventDate),
            "admission": admission.rawValue,
            "requiresRegistration": requiresRegistration,
            "registrationAlertDismissed": registrationAlertDismissed,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let imageUrl = imageUrl {
            dict["imageUrl"] = imageUrl
        } else if forUpdate {
            dict["imageUrl"] = FieldValue.delete()
        }
        
        if let startTime = startTime {
            dict["startTime"] = Timestamp(date: startTime)
        } else if forUpdate {
            dict["startTime"] = FieldValue.delete()
        }
        
        if let endTime = endTime {
            dict["endTime"] = Timestamp(date: endTime)
        } else if forUpdate {
            dict["endTime"] = FieldValue.delete()
        }
        
        if let urlLink = urlLink, !urlLink.isEmpty {
            dict["urlLink"] = urlLink
        } else if forUpdate {
            dict["urlLink"] = FieldValue.delete()
        }
        
        if let admissionAmount = admissionAmount {
            dict["admissionAmount"] = admissionAmount
        } else if forUpdate {
            dict["admissionAmount"] = FieldValue.delete()
        }
        
        if let registrationDeadline = registrationDeadline {
            dict["registrationDeadline"] = Timestamp(date: registrationDeadline)
        } else if forUpdate {
            dict["registrationDeadline"] = FieldValue.delete()
        }
        
        if let category = category {
            dict["category"] = category.rawValue
        } else if forUpdate {
            dict["category"] = FieldValue.delete()
        }
        
        if let notes = notes, !notes.isEmpty {
            dict["notes"] = notes
        } else if forUpdate {
            dict["notes"] = FieldValue.delete()
        }
        
        if let location = location, !location.isEmpty {
            dict["location"] = location
        } else if forUpdate {
            dict["location"] = FieldValue.delete()
        }
        
        if let appleCalendarEventId = appleCalendarEventId {
            dict["appleCalendarEventId"] = appleCalendarEventId
        } else if forUpdate {
            dict["appleCalendarEventId"] = FieldValue.delete()
        }
        
        if let googleCalendarEventId = googleCalendarEventId {
            dict["googleCalendarEventId"] = googleCalendarEventId
        } else if forUpdate {
            dict["googleCalendarEventId"] = FieldValue.delete()
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> Event? {
        guard let userId = dict["userId"] as? String,
              let name = dict["name"] as? String,
              let eventDateTimestamp = dict["eventDate"] as? Timestamp,
              let admissionRaw = dict["admission"] as? String,
              let admission = AdmissionType(rawValue: admissionRaw),
              let requiresRegistration = dict["requiresRegistration"] as? Bool,
              let statusRaw = dict["status"] as? String,
              let status = EventStatus(rawValue: statusRaw),
              let createdAtTimestamp = dict["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dict["updatedAt"] as? Timestamp
        else {
            return nil
        }
        
        let imageUrl = dict["imageUrl"] as? String
        let startTime = (dict["startTime"] as? Timestamp)?.dateValue()
        let endTime = (dict["endTime"] as? Timestamp)?.dateValue()
        let urlLink = dict["urlLink"] as? String
        let admissionAmount = dict["admissionAmount"] as? Double
        let registrationDeadline = (dict["registrationDeadline"] as? Timestamp)?.dateValue()
        let registrationAlertDismissed = dict["registrationAlertDismissed"] as? Bool ?? false
        let categoryRaw = dict["category"] as? String
        let category = categoryRaw.flatMap { EventCategory(rawValue: $0) }
        let notes = dict["notes"] as? String
        let location = dict["location"] as? String
        let appleCalendarEventId = dict["appleCalendarEventId"] as? String
        let googleCalendarEventId = dict["googleCalendarEventId"] as? String
        
        return Event(
            id: id,
            userId: userId,
            name: name,
            imageUrl: imageUrl,
            eventDate: eventDateTimestamp.dateValue(),
            startTime: startTime,
            endTime: endTime,
            urlLink: urlLink,
            admission: admission,
            admissionAmount: admissionAmount,
            requiresRegistration: requiresRegistration,
            registrationDeadline: registrationDeadline,
            registrationAlertDismissed: registrationAlertDismissed,
            category: category,
            notes: notes,
            location: location,
            status: status,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            appleCalendarEventId: appleCalendarEventId,
            googleCalendarEventId: googleCalendarEventId
        )
    }
}

// MARK: - Stub Repository

struct StubEventWebRepository: EventWebRepository {
    
    func createEvent(_ event: Event) async throws {
        print("StubEventWebRepository - Create event stub")
    }
    
    func getEvent(id: String) async throws -> Event? {
        print("StubEventWebRepository - Get event stub")
        return nil
    }
    
    func getEvents(forUserId userId: String) async throws -> [Event] {
        print("StubEventWebRepository - Get events for user: \(userId)")
        return []
    }
    
    func updateEvent(_ event: Event) async throws {
        print("StubEventWebRepository - Update event stub")
    }
    
    func deleteEvent(id: String) async throws {
        print("StubEventWebRepository - Delete event stub")
    }
    
    func uploadEventImage(_ image: UIImage, userId: String, eventId: String) async throws -> String {
        print("StubEventWebRepository - Upload image stub")
        return ""
    }
    
    func deleteEventImage(userId: String, eventId: String) async throws {
        print("StubEventWebRepository - Delete image stub")
    }
}
