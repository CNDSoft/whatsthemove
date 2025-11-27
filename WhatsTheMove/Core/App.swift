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
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreenView(
                    onRegister: {
                        dismissLaunchScreen()
                    },
                    onSignIn: {
                        dismissLaunchScreen()
                    }
                )
                .transition(.opacity)
            } else {
                CountriesList()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showLaunchScreen)
        .onReceive(showLaunchScreenUpdate) { self.showLaunchScreen = $0 }
    }
    
    private var showLaunchScreenUpdate: AnyPublisher<Bool, Never> {
        injected.appState.updates(for: \.system.showLaunchScreen)
    }
    
    private func dismissLaunchScreen() {
        injected.appState[\.system.showLaunchScreen] = false
    }
}
