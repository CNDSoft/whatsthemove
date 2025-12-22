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
        let content = notification.request.content
        handleRemoteNotification(userInfo: content.userInfo)
        
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content
        handleRemoteNotification(userInfo: content.userInfo)
        
        completionHandler()
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
