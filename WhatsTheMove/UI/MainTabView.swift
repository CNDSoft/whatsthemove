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
    @State private var showAddEvent: Bool = false
    
    enum Tab {
        case home
        case saved
        case profile
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddEvent) {
            AddEventView()
                .inject(injected)
        }
    }
}

// MARK: - Tab Content

private extension MainTabView {
    
    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .saved:
            SavedEmptyView()
        case .profile:
            ProfileView()
        }
    }
}

// MARK: - Custom Tab Bar

private extension MainTabView {
    
    var customTabBar: some View {
        HStack(spacing: 10) {
            tabBarPill
            addButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    var tabBarPill: some View {
        HStack(spacing: 0) {
            tabItem(tab: .home, icon: "home", label: "Home")
            tabItem(tab: .saved, icon: "bookmark", label: "Saved")
            tabItem(tab: .profile, icon: "profile", label: "Profile")
        }
        .padding(3)
        .frame(width: 275, height: 50)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.15), radius: 7, x: 0, y: 0)
    }
    
    func tabItem(tab: Tab, icon: String, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 10) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color(hex: "11104B"))
                
                if selectedTab == tab {
                    Text(label)
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                        .lineLimit(1)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if selectedTab == tab {
                        Color(hex: "11104B").opacity(0.06)
                    } else {
                        Color.clear
                    }
                }
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    var addButton: some View {
        Button {
            showAddEvent = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "F8F7F1"))
                .frame(width: 50, height: 50)
                .background(Color(hex: "11104B"))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty Tab Views

private struct SavedEmptyView: View {
    var body: some View {
        Color(hex: "F8F7F1")
            .ignoresSafeArea()
    }
}


// MARK: - Previews

#Preview {
    MainTabView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
