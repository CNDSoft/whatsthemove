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
    func getAllEvents(forceReload: Bool) async throws -> [Event]
    func loadMoreEvents(currentEvents: [Event], pageSize: Int) async throws -> [Event]
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
    
    func getAllEvents(forceReload: Bool = false) async throws -> [Event] {
        print("RealEventInteractor - Getting all events (forceReload: \(forceReload))")
        
        let cachedEvents = await MainActor.run {
            appState[\.userData.events]
        }
        
        if !forceReload && !cachedEvents.isEmpty {
            print("RealEventInteractor - Returning \(cachedEvents.count) cached events")
            return cachedEvents
        }
        
        let events = try await eventWebRepository.getAllEvents(limit: 20, lastEventDate: nil)
        
        await MainActor.run {
            appState[\.userData.events] = events
        }
        
        print("RealEventInteractor - Retrieved and cached \(events.count) total events")
        return events
    }
    
    func loadMoreEvents(currentEvents: [Event], pageSize: Int = 20) async throws -> [Event] {
        print("RealEventInteractor - Loading more events (current count: \(currentEvents.count))")
        
        let lastEventDate = currentEvents.last?.eventDate
        let newEvents = try await eventWebRepository.getAllEvents(limit: pageSize, lastEventDate: lastEventDate)
        
        let allEvents = currentEvents + newEvents
        
        await MainActor.run {
            appState[\.userData.events] = allEvents
        }
        
        print("RealEventInteractor - Loaded \(newEvents.count) new events, total: \(allEvents.count)")
        return allEvents
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

// MARK: - Event Filtering (Default Implementation)

extension EventInteractor {
    
    func filterEvents(_ events: [Event], by filter: EventFilter) -> [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        switch filter {
        case .tonight:
            return events.filter { calendar.isDateInToday($0.eventDate) }
            
        case .thisWeekend:
            let weekday = calendar.component(.weekday, from: now)
            let daysUntilSaturday = (7 - weekday) % 7
            let daysUntilSunday = daysUntilSaturday + 1
            
            guard let saturday = calendar.date(byAdding: .day, value: daysUntilSaturday == 0 ? 0 : daysUntilSaturday, to: now),
                  let sunday = calendar.date(byAdding: .day, value: daysUntilSunday == 1 ? 1 : daysUntilSunday, to: now) else {
                return []
            }
            
            return events.filter { event in
                calendar.isDate(event.eventDate, inSameDayAs: saturday) ||
                calendar.isDate(event.eventDate, inSameDayAs: sunday)
            }
            
        case .nextWeek:
            guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: now),
                  let startOfNextWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: nextWeekStart)),
                  let endOfNextWeek = calendar.date(byAdding: .day, value: 6, to: startOfNextWeek) else {
                return []
            }
            
            return events.filter { $0.eventDate >= startOfNextWeek && $0.eventDate <= endOfNextWeek }
            
        case .thisMonth:
            return events.filter { calendar.isDate($0.eventDate, equalTo: now, toGranularity: .month) }
            
        case .recentlySaved:
            return events.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    func eventCount(_ events: [Event], for filter: EventFilter) -> Int {
        return filterEvents(events, by: filter).count
    }
    
    func firstNonEmptyFilter(for events: [Event]) -> EventFilter {
        for filter in EventFilter.allCases {
            if eventCount(events, for: filter) > 0 {
                return filter
            }
        }
        return .tonight
    }
}

// MARK: - Saved Events Filtering

extension EventInteractor {
    
    func filterUserEvents(
        _ events: [Event],
        by filter: SavedFilterType,
        userId: String,
        starredIds: Set<String>
    ) -> [Event] {
        let userEvents = events.filter { $0.userId == userId }
        
        switch filter {
        case .allEvents:
            return userEvents.sorted { $0.eventDate < $1.eventDate }
        case .favorites:
            return userEvents.filter { starredIds.contains($0.id) }
                .sorted { $0.eventDate < $1.eventDate }
        case .pastEvents:
            let now = Date()
            return userEvents.filter { $0.eventDate < now }
                .sorted { $0.eventDate > $1.eventDate }
        }
    }
    
    func searchEvents(_ events: [Event], query: String) -> [Event] {
        guard !query.isEmpty else { return events }
        
        let lowercasedQuery = query.lowercased()
        return events.filter { event in
            event.name.lowercased().contains(lowercasedQuery) ||
            event.notes?.lowercased().contains(lowercasedQuery) == true ||
            event.location?.lowercased().contains(lowercasedQuery) == true
        }
    }
    
    func getAvailableCategories(from events: [Event]) -> [EventCategory] {
        let categories = Set(events.compactMap { $0.category })
        return EventCategory.allCases.filter { categories.contains($0) }
    }
    
    func userEventCount(
        _ events: [Event],
        for filter: SavedFilterType,
        userId: String,
        starredIds: Set<String>
    ) -> Int {
        return filterUserEvents(events, by: filter, userId: userId, starredIds: starredIds).count
    }
}

