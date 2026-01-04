//
//  CountriesApp.swift
//  WhatsTheMove
//
//  Created by Alexey on 7/11/24.
//  Copyright © 2024 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine
import EnvironmentOverrides
import FirebaseAuth
import UserNotifications

@main
struct MainApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            appDelegate.rootView
        }
    }
}

extension AppEnvironment {
    var rootView: some View {
        VStack {
            if isRunningTests {
                Text("Running unit tests")
            } else {
                RootContent()
                    .modifier(RootViewAppearance())
                    .modelContainer(modelContainer)
                    .attachEnvironmentOverrides(onChange: onChangeHandler)
                    .inject(diContainer)
                if modelContainer.isStub {
                    Text("⚠️ There is an issue with local database")
                        .font(.caption2)
                }
            }
        }
    }

    private var onChangeHandler: (EnvironmentValues.Diff) -> Void {
        return { diff in
            if !diff.isDisjoint(with: [.locale, .sizeCategory]) {
                self.diContainer.appState[\.routing] = AppState.ViewRouting()
            }
        }
    }
}

// MARK: - Root Content

private struct RootContent: View {
    
    private static let onboardingCompletedKey = "hasCompletedOnboarding"
    private static let hasLaunchedBeforeKey = "hasLaunchedBefore"
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var showLaunchScreen: Bool = true
    @State private var isAuthenticated: Bool = false
    @State private var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: onboardingCompletedKey)
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
            } else {
                if isAuthenticated {
                    if hasCompletedOnboarding {
                        MainTabView()
                            .transition(.opacity)
                    } else {
                        OnboardingView(
                            onComplete: completeOnboarding,
                            onRequestCameraAccess: requestCameraAccess,
                            onRequestNotifications: requestNotifications
                        )
                        .transition(.opacity)
                    }
                } else {
                    AuthView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showLaunchScreen)
        .animation(.easeInOut(duration: 0.3), value: isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .onReceive(isAuthenticatedUpdate) { self.isAuthenticated = $0 }
        .onReceive(hasCompletedOnboardingUpdate) { self.hasCompletedOnboarding = $0 }
        .task {
            await checkAuthAndDismissLaunchScreen()
        }
    }
    
    private var isAuthenticatedUpdate: AnyPublisher<Bool, Never> {
        injected.appState.updates(for: \.userData.isAuthenticated)
    }
    
    private var hasCompletedOnboardingUpdate: AnyPublisher<Bool, Never> {
        injected.appState.updates(for: \.userData.hasCompletedOnboarding)
    }
    
    private func checkAuthAndDismissLaunchScreen() async {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: Self.hasLaunchedBeforeKey)
        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: Self.hasLaunchedBeforeKey)
            try? Auth.auth().signOut()
            print("RootContent - First launch detected, cleared stale Firebase auth")
        }
        
        let authStatus = await injected.interactors.auth.checkAuthStatus()
        isAuthenticated = authStatus
        
        if authStatus {
            try? await injected.interactors.users.loadStarredEventIds()
            await injected.interactors.users.syncTimezoneIfNeeded()
            
            do {
                print("RootContent - Fetching events during launch")
                let events = try await injected.interactors.events.getAllEvents(forceReload: true)
                print("RootContent - Fetched \(events.count) events")
                
                let imageUrls = events.compactMap { event -> URL? in
                    guard let imageUrlString = event.imageUrl else { return nil }
                    return URL(string: imageUrlString)
                }
                
                if !imageUrls.isEmpty {
                    print("RootContent - Preloading \(imageUrls.count) event images")
                    await injected.interactors.images.preloadImages(urls: imageUrls)
                    print("RootContent - Finished preloading images")
                }
            } catch {
                print("RootContent - Failed to fetch events or preload images: \(error.localizedDescription)")
            }
        }
        
        let onboardingCompleted = UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
        hasCompletedOnboarding = onboardingCompleted
        injected.appState[\.userData.hasCompletedOnboarding] = onboardingCompleted
        
        if authStatus && onboardingCompleted {
            await requestPushNotificationIfNeeded()
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            injected.appState[\.system.isLoadingInitialData] = false
        }
        
        showLaunchScreen = false
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
        injected.appState[\.userData.hasCompletedOnboarding] = true
    }
    
    private func requestCameraAccess() {
        injected.interactors.userPermissions.request(permission: .camera)
    }
    
    private func requestNotifications() {
        injected.interactors.userPermissions.request(permission: .pushNotifications)
    }
    
    private func requestPushNotificationIfNeeded() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        guard settings.authorizationStatus == .notDetermined else {
            return
        }
        
        injected.interactors.userPermissions.request(permission: .pushNotifications)
    }
}
