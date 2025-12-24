//
//  Notification.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/11/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

enum NotificationType: String, CaseIterable, Codable {
    case event = "Event"
    case registration = "Registration"
    case general = "General"
    case deadline = "Deadline"
    
    var iconName: String {
        switch self {
        case .event: return "calendar"
        case .registration: return "welcome"
        case .general: return "bell"
        case .deadline: return "welcome"
        }
    }
}

enum NotificationFilter: String, CaseIterable {
    case all = "All"
    case unread = "Unread"
    case event = "Event"
    case registration = "Registration"
}

struct NotificationItem: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let type: NotificationType
    var title: String
    var message: String
    var actionText: String?
    var actionUrl: String?
    var eventId: String?
    var isRead: Bool
    let timestamp: Date
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: NotificationType,
        title: String,
        message: String,
        actionText: String? = nil,
        actionUrl: String? = nil,
        eventId: String? = nil,
        isRead: Bool = false,
        timestamp: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.actionText = actionText
        self.actionUrl = actionUrl
        self.eventId = eventId
        self.isRead = isRead
        self.timestamp = timestamp
        self.createdAt = createdAt
    }
}

extension NotificationItem {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "type": type.rawValue,
            "title": title,
            "message": message,
            "isRead": isRead,
            "timestamp": timestamp,
            "createdAt": createdAt
        ]
        if let actionText = actionText {
            dict["actionText"] = actionText
        }
        if let actionUrl = actionUrl {
            dict["actionUrl"] = actionUrl
        }
        if let eventId = eventId {
            dict["eventId"] = eventId
        }
        return dict
    }
    
    static func fromDictionary(_ data: [String: Any], id: String, userId: String) -> NotificationItem? {
        guard let typeString = data["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let title = data["title"] as? String,
              let message = data["message"] as? String else {
            return nil
        }
        
        let actionText = data["actionText"] as? String
        let actionUrl = data["actionUrl"] as? String
        let eventId = data["eventId"] as? String
        let isRead = (data["isRead"] as? Bool) ?? false
        let timestamp = (data["timestamp"] as? Date) ?? Date()
        let createdAt = (data["createdAt"] as? Date) ?? Date()
        
        return NotificationItem(
            id: id,
            userId: userId,
            type: type,
            title: title,
            message: message,
            actionText: actionText,
            actionUrl: actionUrl,
            eventId: eventId,
            isRead: isRead,
            timestamp: timestamp,
            createdAt: createdAt
        )
    }
}

