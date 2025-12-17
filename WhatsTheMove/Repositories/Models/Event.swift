//
//  Event.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

// MARK: - CalendarType

enum CalendarType: String, Codable, Identifiable {
    case apple
    case google
    
    var id: String { rawValue }
}

// MARK: - AdmissionType

enum AdmissionType: String, Codable {
    case free
    case paid
}

// MARK: - EventCategory

enum EventCategory: String, CaseIterable, Codable {
    case music = "Music"
    case art = "Art"
    case outdoor = "Outdoor"
    case lifestyle = "Lifestyle"
    case sport = "Sport"
    case fitness = "Fitness"
    case travel = "Travel"
    case technology = "Technology"
    case community = "Community"
    case food = "Food"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .music: return "music"
        case .art: return "art"
        case .outdoor: return "outdoor"
        case .lifestyle: return "lifestyle"
        case .sport: return "sport"
        case .fitness: return "fitness"
        case .travel: return "travel"
        case .technology: return "technology"
        case .community: return "community"
        case .food: return "food"
        case .other: return "other"
        }
    }
}

// MARK: - EventStatus

enum EventStatus: String, CaseIterable, Codable {
    case interested = "Interested"
    case going = "Going"
    case waitlisted = "Waitlisted"
}

// MARK: - EventFilter

enum EventFilter: String, CaseIterable {
    case tonight = "Tonight"
    case thisWeekend = "This Weekend"
    case nextWeek = "Next Week"
    case thisMonth = "This Month"
    case recentlySaved = "Recently Saved"
}

// MARK: - Event

struct Event: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let userId: String
    var name: String
    var imageUrl: String?
    var eventDate: Date
    var startTime: Date?
    var endTime: Date?
    var urlLink: String?
    var admission: AdmissionType
    var admissionAmount: Double?
    var requiresRegistration: Bool
    var registrationDeadline: Date?
    var category: EventCategory?
    var notes: String?
    var location: String?
    var status: EventStatus
    let createdAt: Date
    var updatedAt: Date
    var appleCalendarEventId: String?
    var googleCalendarEventId: String?
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        imageUrl: String? = nil,
        eventDate: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        urlLink: String? = nil,
        admission: AdmissionType = .free,
        admissionAmount: Double? = nil,
        requiresRegistration: Bool = false,
        registrationDeadline: Date? = nil,
        category: EventCategory? = nil,
        notes: String? = nil,
        location: String? = nil,
        status: EventStatus = .interested,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        appleCalendarEventId: String? = nil,
        googleCalendarEventId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.imageUrl = imageUrl
        self.eventDate = eventDate
        self.startTime = startTime
        self.endTime = endTime
        self.urlLink = urlLink
        self.admission = admission
        self.admissionAmount = admissionAmount
        self.requiresRegistration = requiresRegistration
        self.registrationDeadline = registrationDeadline
        self.category = category
        self.notes = notes
        self.location = location
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.appleCalendarEventId = appleCalendarEventId
        self.googleCalendarEventId = googleCalendarEventId
    }
}

// MARK: - Event Validation

extension Event {
    
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Event name is required")
        }
        
        if let start = startTime, let end = endTime, isEndTimeSameAsStartTime(start: start, end: end) {
            errors.append("End time must be different from start time")
        }
        
        return errors
    }
    
    private func isEndTimeSameAsStartTime(start: Date, end: Date) -> Bool {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        return startComponents.hour == endComponents.hour && startComponents.minute == endComponents.minute
    }
}
