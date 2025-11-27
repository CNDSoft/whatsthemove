//
//  MainTabView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case search
        case saved
        case profile
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CountriesList()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            Text("Search")
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)
            
            Text("Saved")
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(Tab.saved)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
    }
}

// MARK: - Profile View

private struct ProfileView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let email = injected.appState.value.userData.email {
                        Text(email)
                            .font(.headline)
                    }
                    if let userId = injected.appState.value.userData.userId {
                        Text("User ID: \(userId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Sign Out") {
                        signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private func signOut() {
        Task {
            do {
                try await injected.interactors.auth.signOut()
            } catch {
                print("ProfileView - Error signing out: \(error)")
            }
        }
    }
}

// MARK: - Previews

#Preview {
    MainTabView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}


