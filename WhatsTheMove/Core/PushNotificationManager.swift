//
//  PushNotificationManager.swift
//  WhatsTheMove
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
    
    init(notificationInteractor: NotificationInteractor) {
        self.notificationInteractor = notificationInteractor
        super.init()
        setupNotifications()
    }
    
    func setupNotifications() {
        print("PushNotificationManager - Setting up push notifications")
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    func requestPermission() async {
        print("PushNotificationManager - Requesting push notification permission")
        
        do {
            let granted = try await notificationInteractor.requestPushPermission()
            
            if granted {
                print("PushNotificationManager - Permission granted, registering for remote notifications")
                await registerForRemoteNotifications()
            } else {
                print("PushNotificationManager - Permission denied")
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
        print("PushNotificationManager - Handling remote notification: \(userInfo)")
        
        Task {
            do {
                try await notificationInteractor.loadNotifications()
            } catch {
                print("PushNotificationManager - Error reloading notifications: \(error)")
            }
        }
    }
}

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("PushNotificationManager - Will present notification")
        
        handleRemoteNotification(userInfo: notification.request.content.userInfo)
        
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("PushNotificationManager - Did receive notification response")
        
        handleRemoteNotification(userInfo: response.notification.request.content.userInfo)
        
        completionHandler()
    }
}

extension PushNotificationManager: MessagingDelegate {
    
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("PushNotificationManager - FCM token received: \(fcmToken ?? "nil")")
        
        guard let token = fcmToken else {
            print("PushNotificationManager - No FCM token received")
            return
        }
        
        Task { @MainActor in
            do {
                try await notificationInteractor.registerFCMToken(token)
                print("PushNotificationManager - FCM token registered successfully")
            } catch {
                print("PushNotificationManager - Error registering FCM token: \(error)")
            }
        }
    }
}
