//
//  AppDelegate.swift
//  Whats The Move
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import Foundation
import Firebase
import FirebaseAnalytics
import FirebaseRemoteConfig

@MainActor
final class AppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var environment = AppEnvironment.bootstrap()
    private var systemEventsHandler: SystemEventsHandler { environment.systemEventsHandler }
    private var pushNotificationManager: PushNotificationManager?

    var rootView: some View {
        environment.rootView
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        Messaging.messaging().isAutoInitEnabled = true
        
        let analyticsEnabled = UserDefaults.standard.object(forKey: "analyticsEnabled") as? Bool ?? false
        Analytics.setAnalyticsCollectionEnabled(analyticsEnabled)
        print("AppDelegate - Firebase Analytics collection enabled: \(analyticsEnabled)")
        
        configureRemoteConfig()
        
        pushNotificationManager = PushNotificationManager(
            notificationInteractor: environment.diContainer.interactors.notifications,
            appState: environment.diContainer.appState
        )
        
        return true
    }
    
    private func configureRemoteConfig() {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        
        remoteConfig.configSettings = settings
        print("AppDelegate - Firebase Remote Config configured")
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config: UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        SceneDelegate.register(systemEventsHandler)
        return config
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if DEBUG
        Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
        #endif
        
        systemEventsHandler.handlePushRegistration(result: .success(deviceToken))
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate - ❌ Failed to register for remote notifications: \(error)")
        systemEventsHandler.handlePushRegistration(result: .failure(error))
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        print("AppDelegate - 📬 Received remote notification (app in background/terminated)")
        print("AppDelegate - Notification payload: \(userInfo)")
        
        pushNotificationManager?.handleRemoteNotification(userInfo: userInfo)
        return await systemEventsHandler
            .appDidReceiveRemoteNotification(payload: userInfo)
    }
}

// MARK: - SceneDelegate

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {

    private static var systemEventsHandler: SystemEventsHandler?
    private var systemEventsHandler: SystemEventsHandler? { Self.systemEventsHandler }

    static func register(_ systemEventsHandler: SystemEventsHandler?) {
        Self.systemEventsHandler = systemEventsHandler
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let urlContext = connectionOptions.urlContexts.first {
            systemEventsHandler?.sceneOpenURLContexts([urlContext])
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        systemEventsHandler?.sceneOpenURLContexts(URLContexts)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        systemEventsHandler?.sceneDidBecomeActive()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        systemEventsHandler?.sceneWillResignActive()
    }
}
