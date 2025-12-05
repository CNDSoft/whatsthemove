//
//  EventWebRepository.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import FirebaseFirestore
import UIKit

protocol EventWebRepository {
    func createEvent(_ event: Event) async throws
    func getEvent(id: String) async throws -> Event?
    func getEvents(forUserId userId: String) async throws -> [Event]
    func updateEvent(_ event: Event) async throws
    func deleteEvent(id: String) async throws
    func saveEventImageLocally(_ image: UIImage, eventId: String) throws -> String
    func deleteEventImageLocally(eventId: String)
}

struct RealEventWebRepository: EventWebRepository {
    
    private let db = Firestore.firestore()
    private let collectionName = "events"
    private let fileManager = FileManager.default
    
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
            .order(by: "eventDate", descending: false)
            .getDocuments()
        
        let events = snapshot.documents.compactMap { document -> Event? in
            Event.fromDictionary(document.data(), id: document.documentID)
        }
        
        print("RealEventWebRepository - Retrieved \(events.count) events")
        return events
    }
    
    func updateEvent(_ event: Event) async throws {
        print("RealEventWebRepository - Updating event: \(event.id)")
        
        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        
        try await db.collection(collectionName)
            .document(event.id)
            .updateData(updatedEvent.toDictionary())
        
        print("RealEventWebRepository - Event updated successfully")
    }
    
    func deleteEvent(id: String) async throws {
        print("RealEventWebRepository - Deleting event: \(id)")
        
        deleteEventImageLocally(eventId: id)
        
        try await db.collection(collectionName)
            .document(id)
            .delete()
        
        print("RealEventWebRepository - Event deleted successfully")
    }
    
    func saveEventImageLocally(_ image: UIImage, eventId: String) throws -> String {
        print("RealEventWebRepository - Saving image locally for event: \(eventId)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw EventRepositoryError.imageCompressionFailed
        }
        
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let eventsDirectory = documentsDirectory.appendingPathComponent("EventImages", isDirectory: true)
        
        if !fileManager.fileExists(atPath: eventsDirectory.path) {
            try fileManager.createDirectory(at: eventsDirectory, withIntermediateDirectories: true)
        }
        
        let imagePath = eventsDirectory.appendingPathComponent("\(eventId).jpg")
        try imageData.write(to: imagePath)
        
        print("RealEventWebRepository - Image saved locally: \(imagePath.path)")
        return imagePath.path
    }
    
    func deleteEventImageLocally(eventId: String) {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsDirectory
            .appendingPathComponent("EventImages", isDirectory: true)
            .appendingPathComponent("\(eventId).jpg")
        
        if fileManager.fileExists(atPath: imagePath.path) {
            try? fileManager.removeItem(at: imagePath)
            print("RealEventWebRepository - Deleted local image for event: \(eventId)")
        }
    }
}

// MARK: - EventRepositoryError

enum EventRepositoryError: LocalizedError {
    case imageCompressionFailed
    case eventNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .eventNotFound:
            return "Event not found"
        case .invalidData:
            return "Invalid event data"
        }
    }
}

// MARK: - Event Dictionary Conversion

extension Event {
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "name": name,
            "eventDate": Timestamp(date: eventDate),
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "admission": admission.rawValue,
            "requiresRegistration": requiresRegistration,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let imageUrl = imageUrl {
            dict["imageUrl"] = imageUrl
        }
        
        if let urlLink = urlLink, !urlLink.isEmpty {
            dict["urlLink"] = urlLink
        }
        
        if let admissionAmount = admissionAmount {
            dict["admissionAmount"] = admissionAmount
        }
        
        if let registrationDeadline = registrationDeadline {
            dict["registrationDeadline"] = Timestamp(date: registrationDeadline)
        }
        
        if let category = category {
            dict["category"] = category.rawValue
        }
        
        if let notes = notes, !notes.isEmpty {
            dict["notes"] = notes
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> Event? {
        guard let userId = dict["userId"] as? String,
              let name = dict["name"] as? String,
              let eventDateTimestamp = dict["eventDate"] as? Timestamp,
              let startTimeTimestamp = dict["startTime"] as? Timestamp,
              let endTimeTimestamp = dict["endTime"] as? Timestamp,
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
        let urlLink = dict["urlLink"] as? String
        let admissionAmount = dict["admissionAmount"] as? Double
        let registrationDeadline = (dict["registrationDeadline"] as? Timestamp)?.dateValue()
        let categoryRaw = dict["category"] as? String
        let category = categoryRaw.flatMap { EventCategory(rawValue: $0) }
        let notes = dict["notes"] as? String
        
        return Event(
            id: id,
            userId: userId,
            name: name,
            imageUrl: imageUrl,
            eventDate: eventDateTimestamp.dateValue(),
            startTime: startTimeTimestamp.dateValue(),
            endTime: endTimeTimestamp.dateValue(),
            urlLink: urlLink,
            admission: admission,
            admissionAmount: admissionAmount,
            requiresRegistration: requiresRegistration,
            registrationDeadline: registrationDeadline,
            category: category,
            notes: notes,
            status: status,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
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
        print("StubEventWebRepository - Get events stub")
        return []
    }
    
    func updateEvent(_ event: Event) async throws {
        print("StubEventWebRepository - Update event stub")
    }
    
    func deleteEvent(id: String) async throws {
        print("StubEventWebRepository - Delete event stub")
    }
    
    func saveEventImageLocally(_ image: UIImage, eventId: String) throws -> String {
        print("StubEventWebRepository - Save image locally stub")
        return ""
    }
    
    func deleteEventImageLocally(eventId: String) {
        print("StubEventWebRepository - Delete image locally stub")
    }
}
