//
//  CalendarInteractor.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/17/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

protocol CalendarInteractor {
    func connectAppleCalendar(calendarIdentifier: String, calendarName: String) async throws
    func connectGoogleCalendar(calendarIdentifier: String, calendarName: String) async throws
    func disconnectCalendar() async throws
    func signOutFromGoogle() async throws
    func getAvailableCalendars(for type: CalendarType) async throws -> [CalendarInfo]
    func syncEvent(_ event: Event) async throws
    func syncAllEvents() async throws
    func deleteCalendarEvent(_ event: Event) async throws
    func updateCalendarEvent(_ event: Event) async throws
    func requestCalendarPermission() async throws -> Bool
    func checkCalendarPermission() async -> Bool
    func isGoogleAuthenticated() -> Bool
    func hasRequestedApplePermission() -> Bool
}

struct RealCalendarInteractor: CalendarInteractor {
    
    let appState: Store<AppState>
    let appleCalendarRepository: AppleCalendarRepository
    let googleCalendarRepository: GoogleCalendarRepository
    let eventWebRepository: EventWebRepository
    
    func connectAppleCalendar(calendarIdentifier: String, calendarName: String) async throws {
        print("RealCalendarInteractor - Connecting to Apple Calendar: \(calendarName)")
        
        let hasPermission = try await requestCalendarPermission()
        guard hasPermission else {
            throw CalendarSyncError.permissionDenied
        }
        
        await MainActor.run {
            appState[\.userData.connectedCalendarType] = .apple
            appState[\.userData.selectedCalendarIdentifier] = calendarIdentifier
            appState[\.userData.selectedCalendarName] = calendarName
            appState[\.userData.calendarSyncEnabled] = true
            
            UserDefaults.standard.set(CalendarType.apple.rawValue, forKey: "connectedCalendarType")
            UserDefaults.standard.set(calendarIdentifier, forKey: "selectedCalendarIdentifier")
            UserDefaults.standard.set(calendarName, forKey: "selectedCalendarName")
            UserDefaults.standard.set(true, forKey: "calendarSyncEnabled")
        }
        
        print("RealCalendarInteractor - Apple Calendar connected successfully")
    }
    
    func connectGoogleCalendar(calendarIdentifier: String, calendarName: String) async throws {
        print("RealCalendarInteractor - Connecting to Google Calendar: \(calendarName)")
        
        try await googleCalendarRepository.authenticate()
        
        await MainActor.run {
            appState[\.userData.connectedCalendarType] = .google
            appState[\.userData.selectedCalendarIdentifier] = calendarIdentifier
            appState[\.userData.selectedCalendarName] = calendarName
            appState[\.userData.calendarSyncEnabled] = true
            
            UserDefaults.standard.set(CalendarType.google.rawValue, forKey: "connectedCalendarType")
            UserDefaults.standard.set(calendarIdentifier, forKey: "selectedCalendarIdentifier")
            UserDefaults.standard.set(calendarName, forKey: "selectedCalendarName")
            UserDefaults.standard.set(true, forKey: "calendarSyncEnabled")
        }
        
        print("RealCalendarInteractor - Google Calendar connected successfully")
    }
    
    func disconnectCalendar() async throws {
        print("RealCalendarInteractor - Disconnecting calendar")
        
        let currentType = await appState[\.userData.connectedCalendarType]
        print("RealCalendarInteractor - Current connected type: \(String(describing: currentType))")
        
        if currentType == .google {
            print("RealCalendarInteractor - Calling Google signOut")
            googleCalendarRepository.signOut()
            print("RealCalendarInteractor - Google signOut completed")
        } else {
            print("RealCalendarInteractor - Not Google calendar, skipping signOut")
        }
        
        await MainActor.run {
            appState[\.userData.connectedCalendarType] = nil
            appState[\.userData.selectedCalendarIdentifier] = nil
            appState[\.userData.selectedCalendarName] = nil
            appState[\.userData.calendarSyncEnabled] = false
            appState[\.userData.lastCalendarSyncDate] = nil
            
            UserDefaults.standard.removeObject(forKey: "connectedCalendarType")
            UserDefaults.standard.removeObject(forKey: "selectedCalendarIdentifier")
            UserDefaults.standard.removeObject(forKey: "selectedCalendarName")
            UserDefaults.standard.set(false, forKey: "calendarSyncEnabled")
            UserDefaults.standard.removeObject(forKey: "lastCalendarSyncDate")
        }
        
        print("RealCalendarInteractor - Calendar disconnected successfully")
    }
    
    func getAvailableCalendars(for type: CalendarType) async throws -> [CalendarInfo] {
        print("RealCalendarInteractor - Getting available calendars for type: \(type)")
        
        switch type {
        case .apple:
            let hasPermission = try await requestCalendarPermission()
            guard hasPermission else {
                throw CalendarSyncError.permissionDenied
            }
            return try await appleCalendarRepository.getCalendars()
            
        case .google:
            if !googleCalendarRepository.isAuthenticated() {
                try await googleCalendarRepository.authenticate()
            }
            return try await googleCalendarRepository.getCalendars()
        }
    }
    
    func syncEvent(_ event: Event) async throws {
        print("RealCalendarInteractor - Syncing event: \(event.name)")
        
        guard let calendarType = await MainActor.run(body: { appState[\.userData.connectedCalendarType] }),
              let calendarId = await MainActor.run(body: { appState[\.userData.selectedCalendarIdentifier] }) else {
            print("RealCalendarInteractor - No calendar connected, skipping sync")
            return
        }
        
        switch calendarType {
        case .apple:
            try await syncEventToAppleCalendar(event, calendarId: calendarId)
        case .google:
            try await syncEventToGoogleCalendar(event, calendarId: calendarId)
        }
        
        let syncDate = Date()
        await MainActor.run {
            appState[\.userData.lastCalendarSyncDate] = syncDate
            UserDefaults.standard.set(syncDate, forKey: "lastCalendarSyncDate")
        }
        
        print("RealCalendarInteractor - Event synced successfully")
    }
    
    func syncAllEvents() async throws {
        print("RealCalendarInteractor - Syncing all events")
        
        let events = await MainActor.run {
            appState[\.userData.events]
        }
        
        for event in events {
            do {
                try await syncEvent(event)
            } catch {
                print("RealCalendarInteractor - Failed to sync event \(event.name): \(error)")
            }
        }
        
        print("RealCalendarInteractor - All events synced")
    }
    
    func deleteCalendarEvent(_ event: Event) async throws {
        print("RealCalendarInteractor - Deleting calendar event: \(event.name)")
        
        guard let calendarType = await MainActor.run(body: { appState[\.userData.connectedCalendarType] }) else {
            print("RealCalendarInteractor - No calendar connected, skipping delete")
            return
        }
        
        switch calendarType {
        case .apple:
            if let calendarEventId = event.appleCalendarEventId {
                try await appleCalendarRepository.deleteEvent(calendarEventId: calendarEventId)
            }
            
        case .google:
            if let calendarEventId = event.googleCalendarEventId,
               let calendarId = await MainActor.run(body: { appState[\.userData.selectedCalendarIdentifier] }) {
                try await googleCalendarRepository.deleteEvent(calendarEventId: calendarEventId, in: calendarId)
            }
        }
        
        print("RealCalendarInteractor - Calendar event deleted successfully")
    }
    
    func updateCalendarEvent(_ event: Event) async throws {
        print("RealCalendarInteractor - Updating calendar event: \(event.name)")
        
        guard let calendarType = await MainActor.run(body: { appState[\.userData.connectedCalendarType] }),
              let calendarId = await MainActor.run(body: { appState[\.userData.selectedCalendarIdentifier] }) else {
            print("RealCalendarInteractor - No calendar connected, skipping update")
            return
        }
        
        let includeSourceLinks = await MainActor.run {
            appState[\.userData.includeSourceLinksInCalendar]
        }
        
        switch calendarType {
        case .apple:
            if let calendarEventId = event.appleCalendarEventId {
                try await appleCalendarRepository.updateEvent(event, calendarEventId: calendarEventId, in: calendarId, includeSourceLinks: includeSourceLinks)
            } else {
                try await syncEventToAppleCalendar(event, calendarId: calendarId)
            }
            
        case .google:
            if let calendarEventId = event.googleCalendarEventId {
                try await googleCalendarRepository.updateEvent(event, calendarEventId: calendarEventId, in: calendarId, includeSourceLinks: includeSourceLinks)
            } else {
                try await syncEventToGoogleCalendar(event, calendarId: calendarId)
            }
        }
        
        let syncDate = Date()
        await MainActor.run {
            appState[\.userData.lastCalendarSyncDate] = syncDate
            UserDefaults.standard.set(syncDate, forKey: "lastCalendarSyncDate")
        }
        
        print("RealCalendarInteractor - Calendar event updated successfully")
    }
    
    func requestCalendarPermission() async throws -> Bool {
        print("RealCalendarInteractor - Requesting calendar permission")
        return try await appleCalendarRepository.requestAccess()
    }
    
    func checkCalendarPermission() async -> Bool {
        print("RealCalendarInteractor - Checking calendar permission")
        let hasPermission = (try? await appleCalendarRepository.requestAccess()) ?? false
        return hasPermission
    }
    
    private func syncEventToAppleCalendar(_ event: Event, calendarId: String) async throws {
        print("RealCalendarInteractor - Syncing event to Apple Calendar")
        
        let includeSourceLinks = await MainActor.run {
            appState[\.userData.includeSourceLinksInCalendar]
        }
        
        if let existingCalendarEventId = event.appleCalendarEventId {
            try await appleCalendarRepository.updateEvent(event, calendarEventId: existingCalendarEventId, in: calendarId, includeSourceLinks: includeSourceLinks)
        } else {
            let calendarEventId = try await appleCalendarRepository.createEvent(event, in: calendarId, includeSourceLinks: includeSourceLinks)
            
            var updatedEvent = event
            updatedEvent.appleCalendarEventId = calendarEventId
            
            try await eventWebRepository.updateEvent(updatedEvent)
            
            await MainActor.run {
                var events = appState[\.userData.events]
                if let index = events.firstIndex(where: { $0.id == event.id }) {
                    events[index].appleCalendarEventId = calendarEventId
                    appState[\.userData.events] = events
                }
            }
        }
    }
    
    private func syncEventToGoogleCalendar(_ event: Event, calendarId: String) async throws {
        print("RealCalendarInteractor - Syncing event to Google Calendar")
        
        let includeSourceLinks = await MainActor.run {
            appState[\.userData.includeSourceLinksInCalendar]
        }
        
        if let existingCalendarEventId = event.googleCalendarEventId {
            try await googleCalendarRepository.updateEvent(event, calendarEventId: existingCalendarEventId, in: calendarId, includeSourceLinks: includeSourceLinks)
        } else {
            let calendarEventId = try await googleCalendarRepository.createEvent(event, in: calendarId, includeSourceLinks: includeSourceLinks)
            
            var updatedEvent = event
            updatedEvent.googleCalendarEventId = calendarEventId
            
            try await eventWebRepository.updateEvent(updatedEvent)
            
            await MainActor.run {
                var events = appState[\.userData.events]
                if let index = events.firstIndex(where: { $0.id == event.id }) {
                    events[index].googleCalendarEventId = calendarEventId
                    appState[\.userData.events] = events
                }
            }
        }
    }
    
    func isGoogleAuthenticated() -> Bool {
        return googleCalendarRepository.isAuthenticated()
    }
    
    func signOutFromGoogle() async throws {
        print("RealCalendarInteractor - Signing out from Google")
        googleCalendarRepository.signOut()
        print("RealCalendarInteractor - Google sign out completed")
    }
    
    func hasRequestedApplePermission() -> Bool {
        return appleCalendarRepository.hasRequestedPermission()
    }
}

struct StubCalendarInteractor: CalendarInteractor {
    
    func connectAppleCalendar(calendarIdentifier: String, calendarName: String) async throws {
    }
    
    func connectGoogleCalendar(calendarIdentifier: String, calendarName: String) async throws {
    }
    
    func disconnectCalendar() async throws {
    }
    
    func getAvailableCalendars(for type: CalendarType) async throws -> [CalendarInfo] {
        return [
            CalendarInfo(id: "stub-1", title: "Calendar", source: "iCloud", color: .blue, type: type),
            CalendarInfo(id: "stub-2", title: "Personal", source: "Local", color: .red, type: type)
        ]
    }
    
    func syncEvent(_ event: Event) async throws {
    }
    
    func syncAllEvents() async throws {
    }
    
    func deleteCalendarEvent(_ event: Event) async throws {
    }
    
    func updateCalendarEvent(_ event: Event) async throws {
    }
    
    func requestCalendarPermission() async throws -> Bool {
        return true
    }
    
    func checkCalendarPermission() async -> Bool {
        return true
    }
    
    func isGoogleAuthenticated() -> Bool {
        return true
    }
    
    func signOutFromGoogle() async throws {
    }
    
    func hasRequestedApplePermission() -> Bool {
        return true
    }
}
