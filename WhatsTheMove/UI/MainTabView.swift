//
//  MainTabView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import Combine

struct MainTabView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var selectedTab: Tab = .home
    @State private var showAddEventOptions: Bool = false
    @State private var showAddEvent: Bool = false
    @State private var shouldRefetchEvents: Bool = false
    @State private var showHowToShareSheet: Bool = false
    @State private var sharedEventData: SharedEventData? = nil
    
    enum Tab {
        case home
        case saved
        case profile
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                tabContent
                customTabBar
                
                if showAddEventOptions {
                    addEventOptionsOverlay
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddEvent, onDismiss: {
            shouldRefetchEvents = true
            sharedEventData = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                shouldRefetchEvents = false
            }
        }) {
            AddEventView(sharedData: sharedEventData)
                .inject(injected)
                .id(sharedEventData?.imageData?.count ?? 0)
        }
        .sheet(isPresented: $showHowToShareSheet) {
            HowToShareEventsSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onReceive(showAddEventFromShareUpdate) { shouldShow in
            handleShowAddEventFromShare(shouldShow)
        }
        .onAppear {
            let shouldShow = injected.appState[\.routing.showAddEventFromShare]
            if shouldShow {
                handleShowAddEventFromShare(shouldShow)
            }
        }
    }
    
    private var showAddEventFromShareUpdate: AnyPublisher<Bool, Never> {
        injected.appState.updates(for: \.routing.showAddEventFromShare)
    }
    
    private func handleShowAddEventFromShare(_ shouldShow: Bool) {
        guard shouldShow else { return }
        
        injected.appState[\.routing.showAddEventFromShare] = false
        
        let capturedData = injected.appState[\.routing.sharedEventData]
        sharedEventData = capturedData
        showAddEvent = true
    }
}

// MARK: - Tab Content

private extension MainTabView {
    
    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView(triggerRefetch: $shouldRefetchEvents)
        case .saved:
            SavedEventsView(triggerRefetch: $shouldRefetchEvents)
        case .profile:
            AccountView()
        }
    }
}

// MARK: - Add Event Options Overlay

private extension MainTabView {
    
    var addEventOptionsOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAddEventOptions = false
                    }
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                AddEventOptionsSheet(
                    onManualEntryTapped: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAddEventOptions = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showAddEvent = true
                        }
                    },
                    onShareFromAppTapped: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAddEventOptions = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showHowToShareSheet = true
                        }
                    }
                )
                .frame(height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.15), radius: 7, x: 0, y: 0)
                .padding(.horizontal, 20)
                .padding(.bottom, 95)
            }
        }
        .transition(.opacity)
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
            tabItem(tab: .profile, icon: "profile", label: "Account")
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
            withAnimation(.easeInOut(duration: 0.2)) {
                showAddEventOptions = true
            }
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

// MARK: - Previews

#Preview {
    MainTabView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
