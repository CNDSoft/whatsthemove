//
//  AppleCalendarRepository.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/17/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import EventKit
import SwiftUI

protocol AppleCalendarRepository {
    func requestAccess() async throws -> Bool
    func hasRequestedPermission() -> Bool
    func getCalendars() async throws -> [CalendarInfo]
    func createEvent(_ event: Event, in calendarId: String, includeSourceLinks: Bool) async throws -> String
    func updateEvent(_ event: Event, calendarEventId: String, in calendarId: String, includeSourceLinks: Bool) async throws
    func deleteEvent(calendarEventId: String) async throws
}

struct RealAppleCalendarRepository: AppleCalendarRepository {
    
    let eventStore: EKEventStore
    
    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }
    
    func requestAccess() async throws -> Bool {
        print("RealAppleCalendarRepository - Requesting calendar access")
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            print("RealAppleCalendarRepository - Access granted: \(granted)")
            return granted
        } catch {
            print("RealAppleCalendarRepository - Access request failed: \(error)")
            throw CalendarSyncError.permissionDenied
        }
    }
    
    func hasRequestedPermission() -> Bool {
        let authStatus = EKEventStore.authorizationStatus(for: .event)
        let hasRequested = authStatus != .notDetermined
        print("RealAppleCalendarRepository - Permission requested: \(hasRequested), status: \(authStatus.rawValue)")
        return hasRequested
    }
    
    func getCalendars() async throws -> [CalendarInfo] {
        print("RealAppleCalendarRepository - Fetching calendars")
        
        let authStatus = EKEventStore.authorizationStatus(for: .event)
        guard authStatus == .fullAccess || authStatus == .writeOnly else {
            print("RealAppleCalendarRepository - Calendar access not granted")
            throw CalendarSyncError.permissionDenied
        }
        
        let ekCalendars = eventStore.calendars(for: .event)
        let calendars = ekCalendars.filter { $0.allowsContentModifications }.map { ekCalendar in
            CalendarInfo(
                id: ekCalendar.calendarIdentifier,
                title: ekCalendar.title,
                source: ekCalendar.source.title,
                color: Color(cgColor: ekCalendar.cgColor),
                type: .apple,
                allowsModification: ekCalendar.allowsContentModifications
            )
        }
        
        print("RealAppleCalendarRepository - Found \(calendars.count) writable calendars")
        return calendars
    }
    
    func createEvent(_ event: Event, in calendarId: String, includeSourceLinks: Bool) async throws -> String {
        print("RealAppleCalendarRepository - Creating event: \(event.name)")
        
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            print("RealAppleCalendarRepository - Calendar not found: \(calendarId)")
            throw CalendarSyncError.calendarNotFound
        }
        
        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.calendar = calendar
        ekEvent.title = event.name
        
        if let location = event.location {
            ekEvent.location = location
        }
        
        var notesText = ""
        if let notes = event.notes {
            notesText += notes + "\n\n"
        }
        if includeSourceLinks, let urlLink = event.urlLink {
            notesText += "Event Link: \(urlLink)"
        }
        if !notesText.isEmpty {
            ekEvent.notes = notesText
        }
        
        let startDate: Date
        if let startTime = event.startTime {
            startDate = combineDateAndTime(date: event.eventDate, time: startTime)
        } else {
            startDate = event.eventDate
        }
        
        let endDate: Date
        if let endTime = event.endTime {
            endDate = combineDateAndTime(date: event.eventDate, time: endTime)
        } else {
            endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        }
        
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate
        ekEvent.isAllDay = event.startTime == nil
        
        do {
            try eventStore.save(ekEvent, span: .thisEvent)
            print("RealAppleCalendarRepository - Event created with ID: \(ekEvent.eventIdentifier ?? "unknown")")
            return ekEvent.eventIdentifier ?? ""
        } catch {
            print("RealAppleCalendarRepository - Failed to create event: \(error)")
            throw CalendarSyncError.eventCreationFailed
        }
    }
    
    func updateEvent(_ event: Event, calendarEventId: String, in calendarId: String, includeSourceLinks: Bool) async throws {
        print("RealAppleCalendarRepository - Updating event: \(calendarEventId)")
        
        guard let ekEvent = eventStore.event(withIdentifier: calendarEventId) else {
            print("RealAppleCalendarRepository - Event not found, creating new one")
            _ = try await createEvent(event, in: calendarId, includeSourceLinks: includeSourceLinks)
            return
        }
        
        ekEvent.title = event.name
        
        if let location = event.location {
            ekEvent.location = location
        }
        
        var notesText = ""
        if let notes = event.notes {
            notesText += notes + "\n\n"
        }
        if includeSourceLinks, let urlLink = event.urlLink {
            notesText += "Event Link: \(urlLink)"
        }
        if !notesText.isEmpty {
            ekEvent.notes = notesText
        }
        
        let startDate: Date
        if let startTime = event.startTime {
            startDate = combineDateAndTime(date: event.eventDate, time: startTime)
        } else {
            startDate = event.eventDate
        }
        
        let endDate: Date
        if let endTime = event.endTime {
            endDate = combineDateAndTime(date: event.eventDate, time: endTime)
        } else {
            endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        }
        
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate
        ekEvent.isAllDay = event.startTime == nil
        
        do {
            try eventStore.save(ekEvent, span: .thisEvent)
            print("RealAppleCalendarRepository - Event updated successfully")
        } catch {
            print("RealAppleCalendarRepository - Failed to update event: \(error)")
            throw CalendarSyncError.eventCreationFailed
        }
    }
    
    func deleteEvent(calendarEventId: String) async throws {
        print("RealAppleCalendarRepository - Deleting event: \(calendarEventId)")
        
        guard let ekEvent = eventStore.event(withIdentifier: calendarEventId) else {
            print("RealAppleCalendarRepository - Event not found: \(calendarEventId)")
            return
        }
        
        do {
            try eventStore.remove(ekEvent, span: .thisEvent)
            print("RealAppleCalendarRepository - Event deleted successfully")
        } catch {
            print("RealAppleCalendarRepository - Failed to delete event: \(error)")
            throw CalendarSyncError.eventCreationFailed
        }
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
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
}

struct StubAppleCalendarRepository: AppleCalendarRepository {

    func requestAccess() async throws -> Bool {
        return true
    }
    
    func hasRequestedPermission() -> Bool {
        return true
    }

    func getCalendars() async throws -> [CalendarInfo] {
        return [
            CalendarInfo(id: "stub-1", title: "Calendar", source: "iCloud", color: .blue, type: .apple),
            CalendarInfo(id: "stub-2", title: "Personal", source: "Local", color: .red, type: .apple)
        ]
    }
    
    func createEvent(_ event: Event, in calendarId: String, includeSourceLinks: Bool) async throws -> String {
        return "stub-event-id"
    }
    
    func updateEvent(_ event: Event, calendarEventId: String, in calendarId: String, includeSourceLinks: Bool) async throws {
    }
    
    func deleteEvent(calendarEventId: String) async throws {
    }
}

enum CalendarSyncError: LocalizedError, Equatable {
    case permissionDenied
    case calendarNotFound
    case eventCreationFailed
    case networkError(Error)
    case authenticationFailed
    case invalidEvent
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Calendar access permission denied. Please grant access in Settings."
        case .calendarNotFound:
            return "The selected calendar could not be found."
        case .eventCreationFailed:
            return "Failed to create or update calendar event."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Failed to authenticate with calendar service."
        case .invalidEvent:
            return "The event data is invalid."
        }
    }
    
    static func == (lhs: CalendarSyncError, rhs: CalendarSyncError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied),
             (.calendarNotFound, .calendarNotFound),
             (.eventCreationFailed, .eventCreationFailed),
             (.authenticationFailed, .authenticationFailed),
             (.invalidEvent, .invalidEvent):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
