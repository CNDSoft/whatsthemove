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
    func dismissRegistrationAlert(eventId: String) async throws
}

struct RealEventInteractor: EventInteractor {
    
    let appState: Store<AppState>
    let eventWebRepository: EventWebRepository
    let calendarInteractor: CalendarInteractor
    
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
            appState[\.userData.lastSavedEventId] = eventToSave.id
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
        
        guard let userId = appState[\.userData.userId] else {
            print("RealEventInteractor - No user ID found, returning empty array")
            return []
        }
        
        let events = try await eventWebRepository.getEvents(forUserId: userId)
        
        await MainActor.run {
            appState[\.userData.events] = events
        }
        
        print("RealEventInteractor - Retrieved and cached \(events.count) user events")
        return events
    }
    
    func loadMoreEvents(currentEvents: [Event], pageSize: Int = 20) async throws -> [Event] {
        print("RealEventInteractor - Loading more events (current count: \(currentEvents.count))")
        
        guard let userId = appState[\.userData.userId] else {
            print("RealEventInteractor - No user ID found")
            return currentEvents
        }
        
        let allUserEvents = try await eventWebRepository.getEvents(forUserId: userId)
        
        await MainActor.run {
            appState[\.userData.events] = allUserEvents
        }
        
        print("RealEventInteractor - Loaded all user events, total: \(allUserEvents.count)")
        return allUserEvents
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
            appState[\.userData.lastSavedEventId] = eventToUpdate.id
        }
        
        print("RealEventInteractor - Event updated successfully")
    }
    
    func deleteEvent(id: String) async throws {
        print("RealEventInteractor - Deleting event: \(id)")
        
        let event = try await eventWebRepository.getEvent(id: id)
        
        if let event = event {
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
    
    func dismissRegistrationAlert(eventId: String) async throws {
        print("RealEventInteractor - Dismissing registration alert for event: \(eventId)")
        
        guard var event = try await eventWebRepository.getEvent(id: eventId) else {
            throw EventInteractorError.saveFailed
        }
        
        event.registrationAlertDismissed = true
        event.updatedAt = Date()
        
        try await eventWebRepository.updateEvent(event)
        
        await MainActor.run {
            var events = appState[\.userData.events]
            if let index = events.firstIndex(where: { $0.id == eventId }) {
                events[index].registrationAlertDismissed = true
            }
            appState[\.userData.events] = events
        }
        
        print("RealEventInteractor - Registration alert dismissed successfully")
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
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let now = Date()
        
        let futureEvents = events.filter { !isEventInPast($0, now: now) }
        
        switch filter {
        case .tonight:
            return futureEvents
                .filter { calendar.isDateInToday($0.eventDate) }
                .sorted { effectiveStartDateTime(for: $0) < effectiveStartDateTime(for: $1) }
            
        case .thisWeekend:
            let weekday = calendar.component(.weekday, from: now)
            let daysUntilFriday = weekday == 1 ? -2 : (6 - weekday)
            let daysUntilSunday = (1 - weekday + 7) % 7
            
            guard let friday = calendar.date(byAdding: .day, value: daysUntilFriday, to: now),
                  let sunday = calendar.date(byAdding: .day, value: daysUntilSunday, to: now),
                  let fridayStart = calendar.startOfDay(for: friday) as Date?,
                  let sundayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: sunday) else {
                return []
            }
            
            return futureEvents
                .filter { event in
                    event.eventDate >= fridayStart && event.eventDate <= sundayEnd
                }
                .sorted { effectiveStartDateTime(for: $0) < effectiveStartDateTime(for: $1) }
            
        case .nextWeek:
            guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: now),
                  let startOfNextWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: nextWeekStart)),
                  let endOfNextWeekDay = calendar.date(byAdding: .day, value: 6, to: startOfNextWeek),
                  let endOfNextWeek = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfNextWeekDay) else {
                return []
            }
            
            return futureEvents
                .filter { $0.eventDate >= startOfNextWeek && $0.eventDate <= endOfNextWeek }
                .sorted { effectiveStartDateTime(for: $0) < effectiveStartDateTime(for: $1) }
            
        case .thisMonth:
            return futureEvents
                .filter { calendar.isDate($0.eventDate, equalTo: now, toGranularity: .month) }
                .sorted { effectiveStartDateTime(for: $0) < effectiveStartDateTime(for: $1) }
            
        case .recentlySaved:
            guard let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now) else {
                return []
            }
            
            return futureEvents
                .filter { $0.createdAt >= fiveDaysAgo }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(5)
                .map { $0 }
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
        let now = Date()
        
        switch filter {
        case .upcoming:
            return events.filter { !isEventInPast($0, now: now) }
                .sorted { effectiveStartDateTime(for: $0) < effectiveStartDateTime(for: $1) }
        case .favorites:
            return events.filter { starredIds.contains($0.id) }
                .sorted { effectiveStartDateTime(for: $0) < effectiveStartDateTime(for: $1) }
        case .pastEvents:
            return events.filter { isEventInPast($0, now: now) }
                .sorted { effectiveStartDateTime(for: $0) > effectiveStartDateTime(for: $1) }
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
    
    func determineFilter(for event: Event, in events: [Event]) -> EventFilter? {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let now = Date()
        
        if isEventInPast(event, now: now) {
            return nil
        }
        
        if calendar.isDateInToday(event.eventDate) {
            return .tonight
        }
        
        let weekday = calendar.component(.weekday, from: now)
        let daysUntilFriday = weekday == 1 ? -2 : (6 - weekday)
        let daysUntilSunday = (1 - weekday + 7) % 7
        
        if let friday = calendar.date(byAdding: .day, value: daysUntilFriday, to: now),
           let sunday = calendar.date(byAdding: .day, value: daysUntilSunday, to: now),
           let fridayStart = calendar.startOfDay(for: friday) as Date?,
           let sundayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: sunday) {
            if event.eventDate >= fridayStart && event.eventDate <= sundayEnd {
                return .thisWeekend
            }
        }
        
        if let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: now),
           let startOfNextWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: nextWeekStart)),
           let endOfNextWeekDay = calendar.date(byAdding: .day, value: 6, to: startOfNextWeek),
           let endOfNextWeek = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfNextWeekDay) {
            if event.eventDate >= startOfNextWeek && event.eventDate <= endOfNextWeek {
                return .nextWeek
            }
        }
        
        if calendar.isDate(event.eventDate, equalTo: now, toGranularity: .month) {
            return .thisMonth
        }
        
        if let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now),
           event.createdAt >= fiveDaysAgo {
            return .recentlySaved
        }
        
        return firstNonEmptyFilter(for: events)
    }
    
    func determineSavedFilter(for event: Event, starredIds: Set<String>) -> SavedFilterType {
        let now = Date()
        
        if isEventInPast(event, now: now) {
            return .pastEvents
        }
        
        return .upcoming
    }
    
    private func isEventInPast(_ event: Event, now: Date) -> Bool {
        let calendar = Calendar.current
        
        if let endTime = event.endTime {
            let endDateTime = combineDateTime(date: event.eventDate, time: endTime, calendar: calendar)
            return endDateTime < now
        } else {
            guard let dayAfterEvent = calendar.date(byAdding: .day, value: 1, to: event.eventDate),
                  let startOfDayAfter = calendar.startOfDay(for: dayAfterEvent) as Date? else {
                return false
            }
            return now >= startOfDayAfter
        }
    }
    
    private func combineDateTime(date: Date, time: Date, calendar: Calendar) -> Date {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? date
    }
    
    private func effectiveStartDateTime(for event: Event) -> Date {
        let calendar = Calendar.current
        if let startTime = event.startTime {
            return combineDateTime(date: event.eventDate, time: startTime, calendar: calendar)
        }
        return event.eventDate
    }
}

