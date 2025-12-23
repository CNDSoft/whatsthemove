//
//  User.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

struct NotificationPreferences: Codable, Equatable {
    var eventRemindersEnabled: Bool
    var reminderWeekBefore: Bool
    var reminderDayBefore: Bool
    var reminder3Hours: Bool
    var reminderInterestedDayBefore: Bool
    var registrationDeadlinesEnabled: Bool
    var systemNotificationsEnabled: Bool
    
    init(
        eventRemindersEnabled: Bool = true,
        reminderWeekBefore: Bool = false,
        reminderDayBefore: Bool = true,
        reminder3Hours: Bool = true,
        reminderInterestedDayBefore: Bool = true,
        registrationDeadlinesEnabled: Bool = true,
        systemNotificationsEnabled: Bool = true
    ) {
        self.eventRemindersEnabled = eventRemindersEnabled
        self.reminderWeekBefore = reminderWeekBefore
        self.reminderDayBefore = reminderDayBefore
        self.reminder3Hours = reminder3Hours
        self.reminderInterestedDayBefore = reminderInterestedDayBefore
        self.registrationDeadlinesEnabled = registrationDeadlinesEnabled
        self.systemNotificationsEnabled = systemNotificationsEnabled
    }
}

struct User: Codable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let ageRange: String
    var phoneNumber: String?
    var starredEventIds: [String]
    var notificationPreferences: NotificationPreferences
    var fcmToken: String?
    var analyticsEnabled: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

extension User {
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "ageRange": ageRange,
            "starredEventIds": starredEventIds,
            "notificationPreferences": notificationPreferences.toDictionary(),
            "analyticsEnabled": analyticsEnabled,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        if let phoneNumber = phoneNumber {
            dict["phoneNumber"] = phoneNumber
        }
        if let fcmToken = fcmToken {
            dict["fcmToken"] = fcmToken
        }
        return dict
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> User? {
        guard let email = data["email"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let ageRange = data["ageRange"] as? String else {
            return nil
        }
        
        let phoneNumber = data["phoneNumber"] as? String
        let starredEventIds = (data["starredEventIds"] as? [String]) ?? []
        let fcmToken = data["fcmToken"] as? String
        let analyticsEnabled = (data["analyticsEnabled"] as? Bool) ?? false
        
        let notificationPreferences: NotificationPreferences
        if let prefsDict = data["notificationPreferences"] as? [String: Any] {
            notificationPreferences = NotificationPreferences.fromDictionary(prefsDict)
        } else {
            notificationPreferences = NotificationPreferences()
        }
        
        let createdAt = (data["createdAt"] as? Date) ?? Date()
        let updatedAt = (data["updatedAt"] as? Date) ?? Date()
        
        return User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            ageRange: ageRange,
            phoneNumber: phoneNumber,
            starredEventIds: starredEventIds,
            notificationPreferences: notificationPreferences,
            fcmToken: fcmToken,
            analyticsEnabled: analyticsEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension NotificationPreferences {
    
    func toDictionary() -> [String: Any] {
        return [
            "eventRemindersEnabled": eventRemindersEnabled,
            "reminderWeekBefore": reminderWeekBefore,
            "reminderDayBefore": reminderDayBefore,
            "reminder3Hours": reminder3Hours,
            "reminderInterestedDayBefore": reminderInterestedDayBefore,
            "registrationDeadlinesEnabled": registrationDeadlinesEnabled,
            "systemNotificationsEnabled": systemNotificationsEnabled
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> NotificationPreferences {
        return NotificationPreferences(
            eventRemindersEnabled: (data["eventRemindersEnabled"] as? Bool) ?? true,
            reminderWeekBefore: (data["reminderWeekBefore"] as? Bool) ?? false,
            reminderDayBefore: (data["reminderDayBefore"] as? Bool) ?? true,
            reminder3Hours: (data["reminder3Hours"] as? Bool) ?? true,
            reminderInterestedDayBefore: (data["reminderInterestedDayBefore"] as? Bool) ?? true,
            registrationDeadlinesEnabled: (data["registrationDeadlinesEnabled"] as? Bool) ?? true,
            systemNotificationsEnabled: (data["systemNotificationsEnabled"] as? Bool) ?? true
        )
    }
}



