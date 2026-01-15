//
//  CalendarInteractorTests.swift
//  UnitTests
//
//  Created by Cem Sertkaya on 12/17/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Testing
import SwiftUI
@testable import Whats The Move

@MainActor
@Suite struct CalendarInteractorTests {
    
    let appState: Store<AppState>
    let mockedAppleRepo: MockedAppleCalendarRepository
    let mockedGoogleRepo: MockedGoogleCalendarRepository
    let mockedEventWebRepo: StubEventWebRepository
    let sut: RealCalendarInteractor
    
    let testEvent: Event
    let testCalendarId = "test-calendar-id"
    let testCalendarName = "Test Calendar"
    
    init() {
        appState = Store<AppState>(AppState())
        mockedAppleRepo = MockedAppleCalendarRepository()
        mockedGoogleRepo = MockedGoogleCalendarRepository()
        mockedEventWebRepo = StubEventWebRepository()
        sut = RealCalendarInteractor(
            appState: appState,
            appleCalendarRepository: mockedAppleRepo,
            googleCalendarRepository: mockedGoogleRepo,
            eventWebRepository: mockedEventWebRepo
        )
        testEvent = Event(
            userId: "test-user-id",
            name: "Test Event",
            eventDate: Date(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
    }
    
    @Test func connectAppleCalendar() async throws {
        mockedAppleRepo.accessGranted = true
        mockedAppleRepo.eventIdResponse = "apple-event-id"
        mockedAppleRepo.actions = .init(expected: [.requestAccess])
        
        try await sut.connectAppleCalendar(calendarIdentifier: testCalendarId, calendarName: testCalendarName)
        
        #expect(appState[\.userData.connectedCalendarType] == .apple)
        #expect(appState[\.userData.selectedCalendarIdentifier] == testCalendarId)
        #expect(appState[\.userData.selectedCalendarName] == testCalendarName)
        #expect(appState[\.userData.calendarSyncEnabled] == true)
        mockedAppleRepo.verify()
    }
    
    @Test func connectAppleCalendarPermissionDenied() async throws {
        mockedAppleRepo.accessGranted = false
        mockedAppleRepo.actions = .init(expected: [.requestAccess])
        
        await #expect(throws: CalendarSyncError.self) {
            try await sut.connectAppleCalendar(calendarIdentifier: testCalendarId, calendarName: testCalendarName)
        }
        
        #expect(appState[\.userData.calendarSyncEnabled] == false)
        mockedAppleRepo.verify()
    }
    
    @Test func disconnectCalendar() async throws {
        appState[\.userData.connectedCalendarType] = .apple
        appState[\.userData.selectedCalendarIdentifier] = testCalendarId
        appState[\.userData.selectedCalendarName] = testCalendarName
        appState[\.userData.calendarSyncEnabled] = true
        
        try await sut.disconnectCalendar()
        
        #expect(appState[\.userData.connectedCalendarType] == nil)
        #expect(appState[\.userData.selectedCalendarIdentifier] == nil)
        #expect(appState[\.userData.selectedCalendarName] == nil)
        #expect(appState[\.userData.calendarSyncEnabled] == false)
    }
    
    @Test func getAvailableCalendarsForApple() async throws {
        let testCalendars = [
            CalendarInfo(id: "cal-1", title: "Calendar 1", source: "iCloud", color: .blue, type: .apple),
            CalendarInfo(id: "cal-2", title: "Calendar 2", source: "Local", color: .red, type: .apple)
        ]
        mockedAppleRepo.accessGranted = true
        mockedAppleRepo.calendars = testCalendars
        mockedAppleRepo.actions = .init(expected: [.requestAccess, .getCalendars])
        
        let calendars = try await sut.getAvailableCalendars(for: .apple)
        
        #expect(calendars.count == 2)
        #expect(calendars[0].id == "cal-1")
        #expect(calendars[1].id == "cal-2")
        mockedAppleRepo.verify()
    }
    
    @Test func getAvailableCalendarsForGoogle() async throws {
        let testCalendars = [
            CalendarInfo(id: "gcal-1", title: "Google Calendar", source: "Google", color: .green, type: .google)
        ]
        mockedGoogleRepo.authenticated = true
        mockedGoogleRepo.calendars = testCalendars
        mockedGoogleRepo.actions = .init(expected: [.isAuthenticated, .getCalendars])
        
        let calendars = try await sut.getAvailableCalendars(for: .google)
        
        #expect(calendars.count == 1)
        #expect(calendars[0].id == "gcal-1")
        mockedGoogleRepo.verify()
    }
    
    @Test func syncEventToAppleCalendar() async throws {
        appState[\.userData.connectedCalendarType] = .apple
        appState[\.userData.selectedCalendarIdentifier] = testCalendarId
        appState[\.userData.calendarSyncEnabled] = true
        appState[\.userData.includeSourceLinksInCalendar] = true
        
        mockedAppleRepo.eventIdResponse = "apple-event-id"
        mockedAppleRepo.actions = .init(expected: [.createEvent(testEvent, testCalendarId, true)])
        
        try await sut.syncEvent(testEvent)
        
        #expect(appState[\.userData.lastCalendarSyncDate] != nil)
        mockedAppleRepo.verify()
    }
    
    @Test func syncEventToGoogleCalendar() async throws {
        appState[\.userData.connectedCalendarType] = .google
        appState[\.userData.selectedCalendarIdentifier] = testCalendarId
        appState[\.userData.calendarSyncEnabled] = true
        appState[\.userData.includeSourceLinksInCalendar] = true
        
        mockedGoogleRepo.eventIdResponse = "google-event-id"
        mockedGoogleRepo.actions = .init(expected: [.createEvent(testEvent, testCalendarId, true)])
        
        try await sut.syncEvent(testEvent)
        
        #expect(appState[\.userData.lastCalendarSyncDate] != nil)
        mockedGoogleRepo.verify()
    }
    
    @Test func syncEventNoCalendarConnected() async throws {
        appState[\.userData.calendarSyncEnabled] = false
        
        mockedAppleRepo.actions = .init(expected: [])
        mockedGoogleRepo.actions = .init(expected: [])
        
        try await sut.syncEvent(testEvent)
        
        mockedAppleRepo.verify()
        mockedGoogleRepo.verify()
    }
    
    @Test func updateCalendarEvent() async throws {
        var eventWithId = testEvent
        eventWithId.appleCalendarEventId = "existing-apple-event-id"
        
        appState[\.userData.connectedCalendarType] = .apple
        appState[\.userData.selectedCalendarIdentifier] = testCalendarId
        appState[\.userData.calendarSyncEnabled] = true
        appState[\.userData.includeSourceLinksInCalendar] = true
        
        mockedAppleRepo.actions = .init(expected: [.updateEvent(eventWithId, "existing-apple-event-id", testCalendarId, true)])
        
        try await sut.updateCalendarEvent(eventWithId)
        
        mockedAppleRepo.verify()
    }
    
    @Test func deleteCalendarEvent() async throws {
        var eventWithId = testEvent
        eventWithId.appleCalendarEventId = "apple-event-to-delete"
        
        appState[\.userData.connectedCalendarType] = .apple
        appState[\.userData.calendarSyncEnabled] = true
        
        mockedAppleRepo.actions = .init(expected: [.deleteEvent("apple-event-to-delete")])
        
        try await sut.deleteCalendarEvent(eventWithId)
        
        mockedAppleRepo.verify()
    }
    
    @Test func requestCalendarPermission() async throws {
        mockedAppleRepo.accessGranted = true
        mockedAppleRepo.actions = .init(expected: [.requestAccess])
        
        let granted = try await sut.requestCalendarPermission()
        
        #expect(granted == true)
        mockedAppleRepo.verify()
    }
    
    @Test func stubCalendarInteractor() async throws {
        let stubInteractor = StubCalendarInteractor()
        
        try await stubInteractor.connectAppleCalendar(calendarIdentifier: testCalendarId, calendarName: testCalendarName)
        try await stubInteractor.disconnectCalendar()
        
        let calendars = try await stubInteractor.getAvailableCalendars(for: .apple)
        #expect(calendars.count == 2)
        
        try await stubInteractor.syncEvent(testEvent)
        try await stubInteractor.updateCalendarEvent(testEvent)
        try await stubInteractor.deleteCalendarEvent(testEvent)
        
        let granted = try await stubInteractor.requestCalendarPermission()
        #expect(granted == true)
    }
}
