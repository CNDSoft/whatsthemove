//
//  Event.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

// MARK: - AdmissionType

enum AdmissionType: String, Codable {
    case free
    case paid
}

// MARK: - EventCategory

enum EventCategory: String, CaseIterable, Codable {
    case music = "Music"
    case outdoor = "Outdoor"
    case lifestyle = "Lifestyle"
    case sport = "Sport"
    case travel = "Travel"
    case technology = "Technology"
    case community = "Community"
    case food = "Food"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .music: return "music"
        case .outdoor: return "outdoor"
        case .lifestyle: return "lifestyle"
        case .sport: return "sport"
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
    var startTime: Date
    var endTime: Date
    var urlLink: String?
    var admission: AdmissionType
    var admissionAmount: Double?
    var requiresRegistration: Bool
    var registrationDeadline: Date?
    var category: EventCategory?
    var notes: String?
    var status: EventStatus
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        imageUrl: String? = nil,
        eventDate: Date,
        startTime: Date,
        endTime: Date,
        urlLink: String? = nil,
        admission: AdmissionType = .free,
        admissionAmount: Double? = nil,
        requiresRegistration: Bool = false,
        registrationDeadline: Date? = nil,
        category: EventCategory? = nil,
        notes: String? = nil,
        status: EventStatus = .interested,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
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
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Event Validation

extension Event {
    
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && category != nil
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Event name is required")
        }
        
        if category == nil {
            errors.append("Please select a category")
        }
        
        if isEndTimeSameAsStartTime {
            errors.append("End time must be different from start time")
        }
        
        if admission == .paid && (admissionAmount == nil || admissionAmount! <= 0) {
            errors.append("Admission amount is required for paid events")
        }
        
        if requiresRegistration && registrationDeadline == nil {
            errors.append("Registration deadline is required")
        }
        
        return errors
    }
    
    private var isEndTimeSameAsStartTime: Bool {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        return startComponents.hour == endComponents.hour && startComponents.minute == endComponents.minute
    }
}
