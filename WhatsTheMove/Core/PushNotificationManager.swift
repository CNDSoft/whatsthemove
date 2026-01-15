//
//  PushNotificationManager.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 12/19/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import UserNotifications
import Firebase

@MainActor
class PushNotificationManager: NSObject, ObservableObject {
    
    private let notificationInteractor: NotificationInteractor
    private let appState: Store<AppState>
    
    init(notificationInteractor: NotificationInteractor, appState: Store<AppState>) {
        self.notificationInteractor = notificationInteractor
        self.appState = appState
        super.init()
        setupNotifications()
    }
    
    func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        Messaging.messaging().delegate = self
    }
    
    func requestPermission() async {
        do {
            let granted = try await notificationInteractor.requestPushPermission()
            
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("PushNotificationManager - Error requesting permission: \(error)")
        }
    }
    
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        Task {
            do {
                try await notificationInteractor.loadNotifications()
                print("PushNotificationManager - Notifications reloaded")
            } catch {
                print("PushNotificationManager - Error reloading notifications: \(error)")
            }
        }
    }
    
    private func extractEventId(from userInfo: [AnyHashable: Any]) -> String? {
        if let eventId = userInfo["eventId"] as? String {
            return eventId
        }
        
        if let gcmMessageId = userInfo["gcm.message_id"] as? String {
            print("PushNotificationManager - Received FCM notification: \(gcmMessageId)")
        }
        
        print("PushNotificationManager - No eventId found in notification payload")
        print("PushNotificationManager - Available keys: \(userInfo.keys)")
        return nil
    }
    
    private func extractNotificationId(from userInfo: [AnyHashable: Any]) -> String? {
        if let notificationId = userInfo["notificationId"] as? String {
            return notificationId
        }
        
        print("PushNotificationManager - No notificationId found in notification payload")
        return nil
    }
    
    private func markNotificationAsRead(notificationId: String) async {
        do {
            print("PushNotificationManager - Marking notification as read: \(notificationId)")
            try await notificationInteractor.markAsRead(notificationId: notificationId)
            print("PushNotificationManager - Successfully marked notification as read")
        } catch {
            print("PushNotificationManager - Error marking notification as read: \(error)")
        }
    }
    
    private func determineTargetTab(for eventId: String) -> AppState.MainTab {
        let currentTab = appState[\.routing.selectedTab]
        let notificationOpenedFrom = appState[\.routing.notificationViewOpenedFrom]
        
        if currentTab == .profile {
            return .home
        }
        
        if let openedFrom = notificationOpenedFrom {
            return openedFrom == .home ? .home : .saved
        }
        
        return currentTab
    }
}

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let content = notification.request.content
        handleRemoteNotification(userInfo: content.userInfo)
        
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("PushNotificationManager - User tapped on notification")
        let content = response.notification.request.content
        
        Task {
            do {
                try await notificationInteractor.loadNotifications()
                
                if let eventId = extractEventId(from: content.userInfo) {
                    await MainActor.run {
                        print("PushNotificationManager - Navigating to event: \(eventId)")
                        
                        let selectedTab = determineTargetTab(for: eventId)
                        print("PushNotificationManager - Switching to tab: \(selectedTab)")
                        appState[\.routing.selectedTab] = selectedTab
                        
                        appState[\.userData.notificationTappedEventId] = eventId
                    }
                }
                
                if let notificationId = extractNotificationId(from: content.userInfo) {
                    try? await markNotificationAsRead(notificationId: notificationId)
                }
            } catch {
                print("PushNotificationManager - Error handling notification tap: \(error)")
            }
            
            completionHandler()
        }
    }
}

extension PushNotificationManager: MessagingDelegate {
    
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        Task { @MainActor in
            do {
                try await notificationInteractor.registerFCMToken(token)
            } catch {
                print("PushNotificationManager - Error registering FCM token: \(error)")
            }
        }
    }
}
