//
//  NotificationInteractor.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/19/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import UserNotifications

protocol NotificationInteractor {
    func loadNotifications() async throws
    func markAsRead(notificationId: String) async throws
    func markAllAsRead() async throws
    func deleteNotification(notificationId: String) async throws
    func updatePreferences(_ preferences: NotificationPreferences) async throws
    func loadPreferences() async throws
    func handleNotificationTap(_ notification: NotificationItem) async
    func requestPushPermission() async throws -> Bool
    func registerFCMToken(_ token: String) async throws
}

struct RealNotificationInteractor: NotificationInteractor {
    
    let appState: Store<AppState>
    let notificationWebRepository: NotificationWebRepository
    let userWebRepository: UserWebRepository
    
    func loadNotifications() async throws {
        print("RealNotificationInteractor - Loading notifications")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            print("RealNotificationInteractor - No user ID found")
            return
        }
        
        let notifications = try await notificationWebRepository.getUserNotifications(userId: userId)
        
        await MainActor.run {
            appState[\.userData.notifications] = notifications
        }
        
        let unreadCount = notifications.filter { !$0.isRead }.count
        await updateAppBadge(count: unreadCount)
        
        print("RealNotificationInteractor - Loaded \(notifications.count) notifications")
    }
    
    func markAsRead(notificationId: String) async throws {
        print("RealNotificationInteractor - Marking notification as read: \(notificationId)")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            throw NotificationInteractorError.userNotAuthenticated
        }
        
        try await notificationWebRepository.markNotificationAsRead(userId: userId, notificationId: notificationId)
        
        var unreadCount = 0
        await MainActor.run {
            var notifications = appState[\.userData.notifications]
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index].isRead = true
            }
            appState[\.userData.notifications] = notifications
            unreadCount = notifications.filter { !$0.isRead }.count
        }
        
        await updateAppBadge(count: unreadCount)
        
        print("RealNotificationInteractor - Notification marked as read")
    }
    
    func markAllAsRead() async throws {
        print("RealNotificationInteractor - Marking all notifications as read")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            throw NotificationInteractorError.userNotAuthenticated
        }
        
        try await notificationWebRepository.markAllNotificationsAsRead(userId: userId)
        
        await MainActor.run {
            var notifications = appState[\.userData.notifications]
            for index in notifications.indices {
                notifications[index].isRead = true
            }
            appState[\.userData.notifications] = notifications
        }
        
        await updateAppBadge(count: 0)
        
        print("RealNotificationInteractor - All notifications marked as read")
    }
    
    func deleteNotification(notificationId: String) async throws {
        print("RealNotificationInteractor - Deleting notification: \(notificationId)")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            throw NotificationInteractorError.userNotAuthenticated
        }
        
        try await notificationWebRepository.deleteNotification(userId: userId, notificationId: notificationId)
        
        await MainActor.run {
            var notifications = appState[\.userData.notifications]
            notifications.removeAll { $0.id == notificationId }
            appState[\.userData.notifications] = notifications
        }
        
        print("RealNotificationInteractor - Notification deleted")
    }
    
    func updatePreferences(_ preferences: NotificationPreferences) async throws {
        print("RealNotificationInteractor - Updating notification preferences")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            throw NotificationInteractorError.userNotAuthenticated
        }
        
        try await userWebRepository.updateNotificationPreferences(userId: userId, preferences: preferences)
        
        await MainActor.run {
            appState[\.userData.notificationPreferences] = preferences
        }
        
        print("RealNotificationInteractor - Notification preferences updated")
    }
    
    func loadPreferences() async throws {
        print("RealNotificationInteractor - Loading notification preferences")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            print("RealNotificationInteractor - No user ID found")
            return
        }
        
        let preferences = try await userWebRepository.getNotificationPreferences(userId: userId)
        
        await MainActor.run {
            appState[\.userData.notificationPreferences] = preferences
        }
        
        print("RealNotificationInteractor - Notification preferences loaded")
    }
    
    func handleNotificationTap(_ notification: NotificationItem) async {
        print("RealNotificationInteractor - Handling notification tap: \(notification.id)")
        
        if !notification.isRead {
            try? await markAsRead(notificationId: notification.id)
        }
        
        print("RealNotificationInteractor - Notification tap handled")
    }
    
    func requestPushPermission() async throws -> Bool {
        print("RealNotificationInteractor - Requesting push notification permission")
        
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("RealNotificationInteractor - Push permission granted: \(granted)")
            return granted
        } catch {
            print("RealNotificationInteractor - Failed to request push permission: \(error.localizedDescription)")
            throw NotificationInteractorError.permissionDenied
        }
    }
    
    func registerFCMToken(_ token: String) async throws {
        print("RealNotificationInteractor - Registering FCM token")
        
        var userId: String?
        var attempts = 0
        let maxAttempts = 10
        
        while userId == nil && attempts < maxAttempts {
            userId = await MainActor.run(body: { appState[\.userData.userId] })
            
            if userId == nil {
                print("RealNotificationInteractor - User not authenticated yet, waiting... (attempt \(attempts + 1)/\(maxAttempts))")
                try await Task.sleep(nanoseconds: 500_000_000)
                attempts += 1
            }
        }
        
        guard let userId = userId else {
            print("RealNotificationInteractor - User not authenticated after \(maxAttempts) attempts")
            throw NotificationInteractorError.userNotAuthenticated
        }
        
        try await userWebRepository.updateFCMToken(userId: userId, token: token)
        
        await MainActor.run {
            appState[\.userData.fcmToken] = token
        }
        
        print("RealNotificationInteractor - FCM token registered successfully")
    }
    
    private func updateAppBadge(count: Int) async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
            print("RealNotificationInteractor - Updated app badge to \(count)")
        } catch {
            print("RealNotificationInteractor - Failed to update app badge: \(error)")
        }
    }
}

struct StubNotificationInteractor: NotificationInteractor {
    
    func loadNotifications() async throws {
        print("StubNotificationInteractor - Load notifications stub")
    }
    
    func markAsRead(notificationId: String) async throws {
        print("StubNotificationInteractor - Mark as read stub")
    }
    
    func markAllAsRead() async throws {
        print("StubNotificationInteractor - Mark all as read stub")
    }
    
    func deleteNotification(notificationId: String) async throws {
        print("StubNotificationInteractor - Delete notification stub")
    }
    
    func updatePreferences(_ preferences: NotificationPreferences) async throws {
        print("StubNotificationInteractor - Update preferences stub")
    }
    
    func loadPreferences() async throws {
        print("StubNotificationInteractor - Load preferences stub")
    }
    
    func handleNotificationTap(_ notification: NotificationItem) async {
        print("StubNotificationInteractor - Handle notification tap stub")
    }
    
    func requestPushPermission() async throws -> Bool {
        print("StubNotificationInteractor - Request push permission stub")
        return false
    }
    
    func registerFCMToken(_ token: String) async throws {
        print("StubNotificationInteractor - Register FCM token stub")
    }
}

enum NotificationInteractorError: LocalizedError {
    case userNotAuthenticated
    case permissionDenied
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .permissionDenied:
            return "Push notification permission denied"
        case .loadFailed:
            return "Failed to load notifications"
        }
    }
}
