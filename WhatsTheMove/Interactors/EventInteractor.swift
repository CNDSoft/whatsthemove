//
//  EventInteractor.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import UIKit

protocol EventInteractor {
    func saveEvent(_ event: Event, image: UIImage?) async throws
    func getEvent(id: String) async throws -> Event?
    func getUserEvents() async throws -> [Event]
    func getAllEvents() async throws -> [Event]
    func updateEvent(_ event: Event, newImage: UIImage?) async throws
    func deleteEvent(id: String) async throws
    func validateEvent(_ event: Event) -> [String]
}

struct RealEventInteractor: EventInteractor {
    
    let appState: Store<AppState>
    let eventWebRepository: EventWebRepository
    
    func saveEvent(_ event: Event, image: UIImage?) async throws {
        print("RealEventInteractor - Saving event: \(event.name)")
        
        let validationErrors = validateEvent(event)
        guard validationErrors.isEmpty else {
            throw EventInteractorError.validationFailed(validationErrors)
        }
        
        var eventToSave = event
        
        if let image = image {
            let imageUrl = try await eventWebRepository.uploadEventImage(
                image,
                userId: event.userId,
                eventId: event.id
            )
            eventToSave.imageUrl = imageUrl
        }
        
        try await eventWebRepository.createEvent(eventToSave)
        
        await MainActor.run {
            var events = appState[\.userData.events]
            events.append(eventToSave)
            appState[\.userData.events] = events
        }
        
        print("RealEventInteractor - Event saved successfully: \(event.id)")
    }
    
    func getEvent(id: String) async throws -> Event? {
        print("RealEventInteractor - Getting event: \(id)")
        
        let event = try await eventWebRepository.getEvent(id: id)
        
        print("RealEventInteractor - Event retrieved: \(event?.name ?? "nil")")
        return event
    }
    
    func getUserEvents() async throws -> [Event] {
        print("RealEventInteractor - Getting user events")
        
        guard let userId = appState[\.userData.userId] else {
            print("RealEventInteractor - No user ID found")
            return []
        }
        
        let events = try await eventWebRepository.getEvents(forUserId: userId)
        
        await MainActor.run {
            appState[\.userData.events] = events
        }
        
        print("RealEventInteractor - Retrieved \(events.count) events")
        return events
    }
    
    func getAllEvents() async throws -> [Event] {
        print("RealEventInteractor - Getting all events")
        
        let events = try await eventWebRepository.getAllEvents()
        
        print("RealEventInteractor - Retrieved \(events.count) total events")
        return events
    }
    
    func updateEvent(_ event: Event, newImage: UIImage?) async throws {
        print("RealEventInteractor - Updating event: \(event.id)")
        
        let validationErrors = validateEvent(event)
        guard validationErrors.isEmpty else {
            throw EventInteractorError.validationFailed(validationErrors)
        }
        
        var eventToUpdate = event
        eventToUpdate.updatedAt = Date()
        
        if let image = newImage {
            let imageUrl = try await eventWebRepository.uploadEventImage(
                image,
                userId: event.userId,
                eventId: event.id
            )
            eventToUpdate.imageUrl = imageUrl
        }
        
        try await eventWebRepository.updateEvent(eventToUpdate)
        
        await MainActor.run {
            var events = appState[\.userData.events]
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = eventToUpdate
            }
            appState[\.userData.events] = events
        }
        
        print("RealEventInteractor - Event updated successfully")
    }
    
    func deleteEvent(id: String) async throws {
        print("RealEventInteractor - Deleting event: \(id)")
        
        if let event = try await eventWebRepository.getEvent(id: id) {
            try await eventWebRepository.deleteEventImage(userId: event.userId, eventId: id)
        }
        
        try await eventWebRepository.deleteEvent(id: id)
        
        await MainActor.run {
            var events = appState[\.userData.events]
            events.removeAll { $0.id == id }
            appState[\.userData.events] = events
        }
        
        print("RealEventInteractor - Event deleted successfully")
    }
    
    func validateEvent(_ event: Event) -> [String] {
        return event.validationErrors
    }
}

// MARK: - EventInteractorError

enum EventInteractorError: LocalizedError {
    case validationFailed([String])
    case userNotAuthenticated
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return errors.joined(separator: "\n")
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .saveFailed:
            return "Failed to save event"
        }
    }
}

// MARK: - Stub Interactor

struct StubEventInteractor: EventInteractor {
    
    func saveEvent(_ event: Event, image: UIImage?) async throws {
        print("StubEventInteractor - Save event stub")
    }
    
    func getEvent(id: String) async throws -> Event? {
        print("StubEventInteractor - Get event stub")
        return nil
    }
    
    func getUserEvents() async throws -> [Event] {
        print("StubEventInteractor - Get user events stub")
        return []
    }
    
    func getAllEvents() async throws -> [Event] {
        print("StubEventInteractor - Get all events stub")
        return []
    }
    
    func updateEvent(_ event: Event, newImage: UIImage?) async throws {
        print("StubEventInteractor - Update event stub")
    }
    
    func deleteEvent(id: String) async throws {
        print("StubEventInteractor - Delete event stub")
    }
    
    func validateEvent(_ event: Event) -> [String] {
        print("StubEventInteractor - Validate event stub")
        return []
    }
}
