//
//  HomeView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var selectedFilter: EventFilter = .tonight
    @State private var events: [Event] = []
    @State private var isLoading: Bool = false
    @State private var isLoadingMore: Bool = false
    @State private var errorMessage: String?
    @State private var hasLoadedEvents: Bool = false
    @State private var canLoadMore: Bool = true
    @State private var shouldRefetch: Bool = false
    
    @Binding var triggerRefetch: Bool
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                eventListContent
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
        .task {
            await loadEventsIfNeeded()
        }
        .refreshable {
            await refreshEvents()
        }
        .onChange(of: triggerRefetch) { _, shouldRefetch in
            if shouldRefetch {
                Task {
                    await refreshEvents()
                }
            }
        }
    }
    
    private var filteredEvents: [Event] {
        injected.interactors.events.filterEvents(events, by: selectedFilter)
    }
}

// MARK: - Header Section

private extension HomeView {
    
    var headerSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                headerBackground(width: geometry.size.width)
                
                VStack(alignment: .leading, spacing: 20) {
                    headerTopRow.padding(.horizontal, 20)
                    filterSection
                }
                .padding(.top, 60)
                .frame(width: geometry.size.width, alignment: .leading)
            }
        }
        .frame(height: 180).edgesIgnoringSafeArea(.top)
    }
    
    func headerBackground(width: CGFloat) -> some View {
        ZStack {
            Image("header")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: 250)
                .clipped()
            
            Color.black.opacity(0.5)
        }
        .frame(width: width, height: 250)
    }
    
    var headerTopRow: some View {
        HStack(alignment: .top) {
            titleView
            Spacer()
            notificationButton
        }
    }
    
    var titleView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What's")
                .font(.rubik(.extraBold, size: 30))
                .foregroundColor(.white)
                .textCase(.uppercase)
            Text("the move")
                .font(.rubik(.extraBold, size: 30))
                .foregroundColor(.white)
                .textCase(.uppercase)
        }
        .lineSpacing(0)
    }
    
    var notificationButton: some View {
        Button {
            // Notification action will be implemented later
        } label: {
            Image("bell")
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
    }
    
    var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Events")
                .font(.rubik(.bold, size: 16))
                .foregroundColor(.white)
                .textCase(.uppercase)
                .padding(.leading, 20)
            
            FilterPillsView(
                selectedFilter: $selectedFilter,
                events: events
            )
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Event List Content

private extension HomeView {
    
    @ViewBuilder
    var eventListContent: some View {
        if isLoading {
            loadingView
        } else if filteredEvents.isEmpty {
            emptyStateContent
        } else {
            eventListView
        }
    }
    
    var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading events...")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F"))
                .padding(.top, 10)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var eventListView: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredEvents) { event in
                    EventCardView(event: event)
                        .onAppear {
                            if shouldLoadMore(for: event) {
                                Task {
                                    await loadMoreEvents()
                                }
                            }
                        }
                }
                
                if isLoadingMore {
                    loadingMoreView
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    var loadingMoreView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading more events...")
                .font(.rubik(.regular, size: 12))
                .foregroundColor(Color(hex: "55564F"))
            Spacer()
        }
        .padding(.vertical, 20)
    }
    
    var emptyStateContent: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ticketIconWithBadge
            
            Text("No events found for this time period. Try another filter or add some events.")
                .font(.rubik(.regular, size: 15))
                .frame(width: 215, height: 60)
                .foregroundColor(Color(hex: "55564F"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 80)
    }
    
    var ticketIconWithBadge: some View {
        ZStack(alignment: .topTrailing) {
            ticketIcon
                .frame(width: 60, height: 60)
        }
    }
    
    var ticketIcon: some View {
        Image("empty-ticket")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(Color(hex: "11104B").opacity(0.3))
    }
}

// MARK: - Side Effects

private extension HomeView {
    
    func loadEventsIfNeeded() async {
        guard !hasLoadedEvents else {
            print("HomeView - Events already loaded, skipping")
            return
        }
        
        let cachedEvents = await MainActor.run {
            injected.appState[\.userData.events]
        }
        
        if !cachedEvents.isEmpty {
            print("HomeView - Using \(cachedEvents.count) preloaded events from cache")
            events = cachedEvents
            hasLoadedEvents = true
            canLoadMore = cachedEvents.count >= 20
            selectedFilter = injected.interactors.events.firstNonEmptyFilter(for: events)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedEvents = try await injected.interactors.events.getAllEvents(forceReload: false)
            events = fetchedEvents
            isLoading = false
            hasLoadedEvents = true
            canLoadMore = fetchedEvents.count >= 20
            selectedFilter = injected.interactors.events.firstNonEmptyFilter(for: events)
            print("HomeView - Loaded \(fetchedEvents.count) events")
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("HomeView - Failed to load events: \(error.localizedDescription)")
        }
    }
    
    func refreshEvents() async {
        print("HomeView - Refreshing events")
        
        do {
            let fetchedEvents = try await injected.interactors.events.getAllEvents(forceReload: true)
            events = fetchedEvents
            canLoadMore = fetchedEvents.count >= 20
            selectedFilter = injected.interactors.events.firstNonEmptyFilter(for: events)
            print("HomeView - Refreshed \(fetchedEvents.count) events")
        } catch {
            errorMessage = error.localizedDescription
            print("HomeView - Failed to refresh events: \(error.localizedDescription)")
        }
    }
    
    func loadMoreEvents() async {
        guard !isLoadingMore, canLoadMore else {
            print("HomeView - Already loading more or no more events to load")
            return
        }
        
        isLoadingMore = true
        print("HomeView - Loading more events")
        
        do {
            let updatedEvents = try await injected.interactors.events.loadMoreEvents(currentEvents: events, pageSize: 20)
            
            let newEventsCount = updatedEvents.count - events.count
            events = updatedEvents
            canLoadMore = newEventsCount >= 20
            isLoadingMore = false
            
            print("HomeView - Loaded \(newEventsCount) more events, total: \(updatedEvents.count)")
        } catch {
            errorMessage = error.localizedDescription
            isLoadingMore = false
            print("HomeView - Failed to load more events: \(error.localizedDescription)")
        }
    }
    
    func shouldLoadMore(for event: Event) -> Bool {
        guard let lastEvent = events.last,
              event.id == lastEvent.id,
              canLoadMore,
              !isLoadingMore else {
            return false
        }
        return true
    }
    
}

// MARK: - Previews

#Preview {
    NavigationStack {
        HomeView(triggerRefetch: .constant(false))
    }
    .inject(DIContainer(appState: AppState(), interactors: .stub))
}

