//
//  MockedCalendarRepositories.swift
//  UnitTests
//
//  Created by Cem Sertkaya on 12/17/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Testing
import SwiftUI
@testable import WhatsTheMove

final class MockedAppleCalendarRepository: Mock, AppleCalendarRepository {
    
    enum Action: Equatable {
        case requestAccess
        case getCalendars
        case createEvent(Event, String, Bool)
        case updateEvent(Event, String, String, Bool)
        case deleteEvent(String)
    }
    
    var actions: MockActions<Action>
    var accessGranted: Bool = true
    var calendars: [CalendarInfo] = []
    var eventIdResponse: String = "test-event-id"
    var shouldThrowError: Bool = false
    
    init() {
        actions = .init(expected: [])
    }
    
    func requestAccess() async throws -> Bool {
        register(.requestAccess)
        if shouldThrowError {
            throw CalendarSyncError.permissionDenied
        }
        return accessGranted
    }
    
    func getCalendars() async throws -> [CalendarInfo] {
        register(.getCalendars)
        if shouldThrowError {
            throw CalendarSyncError.permissionDenied
        }
        return calendars
    }
    
    func createEvent(_ event: Event, in calendarId: String, includeSourceLinks: Bool) async throws -> String {
        register(.createEvent(event, calendarId, includeSourceLinks))
        if shouldThrowError {
            throw CalendarSyncError.eventCreationFailed
        }
        return eventIdResponse
    }
    
    func updateEvent(_ event: Event, calendarEventId: String, in calendarId: String, includeSourceLinks: Bool) async throws {
        register(.updateEvent(event, calendarEventId, calendarId, includeSourceLinks))
        if shouldThrowError {
            throw CalendarSyncError.eventCreationFailed
        }
    }
    
    func deleteEvent(calendarEventId: String) async throws {
        register(.deleteEvent(calendarEventId))
        if shouldThrowError {
            throw CalendarSyncError.eventCreationFailed
        }
    }
}

final class MockedGoogleCalendarRepository: Mock, GoogleCalendarRepository {
    
    enum Action: Equatable {
        case authenticate
        case isAuthenticated
        case getCalendars
        case createEvent(Event, String, Bool)
        case updateEvent(Event, String, String, Bool)
        case deleteEvent(String, String)
    }
    
    var actions: MockActions<Action>
    var authenticated: Bool = true
    var calendars: [CalendarInfo] = []
    var eventIdResponse: String = "test-google-event-id"
    var shouldThrowError: Bool = false
    
    init() {
        actions = .init(expected: [])
    }
    
    func authenticate() async throws {
        register(.authenticate)
        if shouldThrowError {
            throw CalendarSyncError.authenticationFailed
        }
    }
    
    func isAuthenticated() -> Bool {
        register(.isAuthenticated)
        return authenticated
    }
    
    func getCalendars() async throws -> [CalendarInfo] {
        register(.getCalendars)
        if shouldThrowError {
            throw CalendarSyncError.authenticationFailed
        }
        return calendars
    }
    
    func createEvent(_ event: Event, in calendarId: String, includeSourceLinks: Bool) async throws -> String {
        register(.createEvent(event, calendarId, includeSourceLinks))
        if shouldThrowError {
            throw CalendarSyncError.eventCreationFailed
        }
        return eventIdResponse
    }
    
    func updateEvent(_ event: Event, calendarEventId: String, in calendarId: String, includeSourceLinks: Bool) async throws {
        register(.updateEvent(event, calendarEventId, calendarId, includeSourceLinks))
        if shouldThrowError {
            throw CalendarSyncError.eventCreationFailed
        }
    }
    
    func deleteEvent(calendarEventId: String, in calendarId: String) async throws {
        register(.deleteEvent(calendarEventId, calendarId))
        if shouldThrowError {
            throw CalendarSyncError.eventCreationFailed
        }
    }
}
