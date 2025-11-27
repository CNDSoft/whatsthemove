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
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var showLaunchScreen: Bool = true
    @State private var isAuthenticated: Bool = false
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
            } else {
                if isAuthenticated {
                    MainTabView()
                        .transition(.opacity)
                } else {
                    AuthView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showLaunchScreen)
        .animation(.easeInOut(duration: 0.3), value: isAuthenticated)
        .onReceive(isAuthenticatedUpdate) { self.isAuthenticated = $0 }
        .task {
            await checkAuthAndDismissLaunchScreen()
        }
    }
    
    private var isAuthenticatedUpdate: AnyPublisher<Bool, Never> {
        injected.appState.updates(for: \.userData.isAuthenticated)
    }
    
    private func checkAuthAndDismissLaunchScreen() async {
        let authStatus = await injected.interactors.auth.checkAuthStatus()
        isAuthenticated = authStatus
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        showLaunchScreen = false
    }
}
