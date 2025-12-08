//
//  StubEventInteractor.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/8/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import UIKit

struct StubEventInteractor: EventInteractor {
    
    func saveEvent(_ event: Event, image: UIImage?) async throws {
        print("StubEventInteractor - Save event stub")
    }
    
    func getEvent(id: String) async throws -> Event? {
        print("StubEventInteractor - Get event stub")
        return Self.previewEvents.first { $0.id == id }
    }
    
    func getUserEvents() async throws -> [Event] {
        print("StubEventInteractor - Get user events stub")
        return Self.previewEvents
    }
    
    func getAllEvents(forceReload: Bool = false) async throws -> [Event] {
        print("StubEventInteractor - Get all events stub")
        return Self.previewEvents
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

// MARK: - Preview Data

extension StubEventInteractor {
    
    static var previewEvents: [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        let todayEvening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
        let todayEndTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now
        
        let weekday = calendar.component(.weekday, from: now)
        let daysUntilSaturday = (7 - weekday) % 7
        let daysUntilSunday = daysUntilSaturday + 1
        let saturday = calendar.date(byAdding: .day, value: max(daysUntilSaturday, 1), to: now) ?? now
        let sunday = calendar.date(byAdding: .day, value: max(daysUntilSunday, 2), to: now) ?? now
        
        let nextWeekDay = calendar.date(byAdding: .day, value: 8, to: now) ?? now
        let nextWeekDay2 = calendar.date(byAdding: .day, value: 10, to: now) ?? now
        
        let laterThisMonth = calendar.date(byAdding: .day, value: 20, to: now) ?? now
        
        return [
            Event(
                userId: "preview",
                name: "Jazz Night Downtown",
                imageUrl: nil,
                eventDate: todayEvening,
                startTime: todayEvening,
                endTime: todayEndTime,
                urlLink: "https://example.com/jazz",
                admission: .paid,
                admissionAmount: 25,
                requiresRegistration: false,
                category: .music,
                status: .going
            ),
            Event(
                userId: "preview",
                name: "Open Mic Comedy",
                imageUrl: nil,
                eventDate: todayEvening,
                startTime: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: now) ?? now,
                endTime: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now) ?? now,
                admission: .free,
                category: .community,
                status: .interested
            ),
            Event(
                userId: "preview",
                name: "Saturday Farmers Market",
                imageUrl: nil,
                eventDate: saturday,
                startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: saturday) ?? saturday,
                endTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: saturday) ?? saturday,
                admission: .free,
                category: .food,
                status: .interested
            ),
            Event(
                userId: "preview",
                name: "Beach Volleyball Tournament",
                imageUrl: nil,
                eventDate: saturday,
                startTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: saturday) ?? saturday,
                endTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: saturday) ?? saturday,
                admission: .paid,
                admissionAmount: 15,
                requiresRegistration: true,
                registrationDeadline: calendar.date(byAdding: .day, value: 2, to: now),
                category: .sport,
                status: .going
            ),
            Event(
                userId: "preview",
                name: "Sunday Brunch Cooking Class",
                imageUrl: nil,
                eventDate: sunday,
                startTime: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: sunday) ?? sunday,
                endTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: sunday) ?? sunday,
                admission: .paid,
                admissionAmount: 45,
                requiresRegistration: true,
                registrationDeadline: saturday,
                category: .food,
                status: .waitlisted
            ),
            Event(
                userId: "preview",
                name: "Tech Meetup: SwiftUI Workshop",
                imageUrl: nil,
                eventDate: nextWeekDay,
                startTime: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: nextWeekDay) ?? nextWeekDay,
                endTime: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: nextWeekDay) ?? nextWeekDay,
                admission: .free,
                requiresRegistration: true,
                registrationDeadline: calendar.date(byAdding: .day, value: 5, to: now),
                category: .technology,
                status: .interested
            ),
            Event(
                userId: "preview",
                name: "Mountain Hiking Trip",
                imageUrl: nil,
                eventDate: nextWeekDay2,
                startTime: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: nextWeekDay2) ?? nextWeekDay2,
                endTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: nextWeekDay2) ?? nextWeekDay2,
                admission: .paid,
                admissionAmount: 30,
                requiresRegistration: true,
                registrationDeadline: nextWeekDay,
                category: .outdoor,
                status: .going
            ),
            Event(
                userId: "preview",
                name: "City Marathon",
                imageUrl: nil,
                eventDate: laterThisMonth,
                startTime: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: laterThisMonth) ?? laterThisMonth,
                endTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: laterThisMonth) ?? laterThisMonth,
                admission: .paid,
                admissionAmount: 50,
                requiresRegistration: true,
                registrationDeadline: calendar.date(byAdding: .day, value: 15, to: now),
                category: .sport,
                status: .interested
            ),
            Event(
                userId: "preview",
                name: "Wine Tasting Festival",
                imageUrl: nil,
                eventDate: laterThisMonth,
                startTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: laterThisMonth) ?? laterThisMonth,
                endTime: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: laterThisMonth) ?? laterThisMonth,
                admission: .paid,
                admissionAmount: 75,
                category: .lifestyle,
                status: .interested
            )
        ]
    }
}
