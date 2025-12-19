//
//  NotificationWebRepository.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/19/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import FirebaseFirestore

protocol NotificationWebRepository {
    func getUserNotifications(userId: String) async throws -> [NotificationItem]
    func markNotificationAsRead(userId: String, notificationId: String) async throws
    func markAllNotificationsAsRead(userId: String) async throws
    func deleteNotification(userId: String, notificationId: String) async throws
    func createNotification(_ notification: NotificationItem) async throws
}

struct RealNotificationWebRepository: NotificationWebRepository {
    
    private let db = Firestore.firestore()
    
    func getUserNotifications(userId: String) async throws -> [NotificationItem] {
        print("RealNotificationWebRepository - Getting notifications for user: \(userId)")
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("notifications")
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
            .getDocuments()
        
        let notifications = snapshot.documents.compactMap { document -> NotificationItem? in
            NotificationItem.fromDictionary(document.data(), id: document.documentID, userId: userId)
        }
        
        print("RealNotificationWebRepository - Retrieved \(notifications.count) notifications")
        return notifications
    }
    
    func markNotificationAsRead(userId: String, notificationId: String) async throws {
        print("RealNotificationWebRepository - Marking notification as read: \(notificationId)")
        
        try await db.collection("users")
            .document(userId)
            .collection("notifications")
            .document(notificationId)
            .updateData(["isRead": true])
        
        print("RealNotificationWebRepository - Notification marked as read")
    }
    
    func markAllNotificationsAsRead(userId: String) async throws {
        print("RealNotificationWebRepository - Marking all notifications as read for user: \(userId)")
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        let batch = db.batch()
        for document in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: document.reference)
        }
        
        try await batch.commit()
        
        print("RealNotificationWebRepository - Marked \(snapshot.documents.count) notifications as read")
    }
    
    func deleteNotification(userId: String, notificationId: String) async throws {
        print("RealNotificationWebRepository - Deleting notification: \(notificationId)")
        
        try await db.collection("users")
            .document(userId)
            .collection("notifications")
            .document(notificationId)
            .delete()
        
        print("RealNotificationWebRepository - Notification deleted")
    }
    
    func createNotification(_ notification: NotificationItem) async throws {
        print("RealNotificationWebRepository - Creating notification: \(notification.id)")
        
        try await db.collection("users")
            .document(notification.userId)
            .collection("notifications")
            .document(notification.id)
            .setData(notification.toDictionary())
        
        print("RealNotificationWebRepository - Notification created successfully")
    }
}

struct StubNotificationWebRepository: NotificationWebRepository {
    
    func getUserNotifications(userId: String) async throws -> [NotificationItem] {
        print("StubNotificationWebRepository - Get user notifications stub")
        return []
    }
    
    func markNotificationAsRead(userId: String, notificationId: String) async throws {
        print("StubNotificationWebRepository - Mark notification as read stub")
    }
    
    func markAllNotificationsAsRead(userId: String) async throws {
        print("StubNotificationWebRepository - Mark all notifications as read stub")
    }
    
    func deleteNotification(userId: String, notificationId: String) async throws {
        print("StubNotificationWebRepository - Delete notification stub")
    }
    
    func createNotification(_ notification: NotificationItem) async throws {
        print("StubNotificationWebRepository - Create notification stub")
    }
}
