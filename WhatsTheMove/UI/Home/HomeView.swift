//
//  HomeView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import Combine

struct HomeView: View {
    
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.injected) private var injected: DIContainer
    @State private var selectedFilter: EventFilter = .tonight
    @State private var events: [Event] = []
    @State private var isLoading: Bool = false
    @State private var isLoadingMore: Bool = false
    @State private var errorMessage: String?
    @State private var hasLoadedEvents: Bool = false
    @State private var canLoadMore: Bool = true
    @State private var shouldRefetch: Bool = false
    @State private var showNotificationAlert: Bool = false
    @State private var eventToEdit: Event?
    @State private var showDeleteConfirmation: Bool = false
    @State private var eventToDelete: Event?
    @State private var isDeleting: Bool = false
    
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
        .onChange(of: triggerRefetch) { _, shouldRefetch in
            if shouldRefetch {
                Task {
                    await refreshEvents()
                    await handleFilterSwitchAfterSave()
                }
            }
        }
        .onReceive(eventsUpdate) { updatedEvents in
            events = updatedEvents
        }
        .sheet(item: $eventToEdit, onDismiss: {
            Task {
                await refreshEvents()
                await handleFilterSwitchAfterSave()
            }
        }) { event in
            AddEventView(mode: .edit(event))
                .inject(injected)
        }
        .alert("Delete Event", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                eventToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let event = eventToDelete {
                    deleteEvent(event)
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .overlay {
            if isDeleting {
                deletingOverlay
            }
        }
        .underDevelopmentAlert(isPresented: $showNotificationAlert)
    }
    
    private var filteredEvents: [Event] {
        return injected.interactors.events.filterEvents(events, by: selectedFilter)
    }
    
    private var eventsUpdate: AnyPublisher<[Event], Never> {
        injected.appState.updates(for: \.userData.events)
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
        .frame(height: 225 - safeAreaInsets.top)
        .edgesIgnoringSafeArea(.top)
    }
    
    func headerBackground(width: CGFloat) -> some View {
        ZStack {
            Image("saved-events-header")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: 225)
                .clipped()
        }
        .frame(width: width, height: 225)
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
            showNotificationAlert = true
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
            
            EventFilterPillsView(
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
                    EventCardView(
                        event: event,
                        showActions: true,
                        onEdit: { event in
                            eventToEdit = event
                        },
                        onDelete: { event in
                            eventToDelete = event
                            showDeleteConfirmation = true
                        }
                    )
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
        .refreshable {
            await refreshEvents()
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
    
    var deletingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Deleting event...")
                    .font(.rubik(.medium, size: 16))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color(hex: "11104B"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
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
    
    func deleteEvent(_ event: Event) {
        isDeleting = true
        
        Task {
            do {
                try await injected.interactors.events.deleteEvent(id: event.id)
                await refreshEvents()
                
                await MainActor.run {
                    isDeleting = false
                    eventToDelete = nil
                }
                
                print("HomeView - Event deleted successfully: \(event.id)")
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = error.localizedDescription
                    eventToDelete = nil
                }
                print("HomeView - Failed to delete event: \(error.localizedDescription)")
            }
        }
    }
    
    func handleFilterSwitchAfterSave() async {
        guard let lastSavedEventId = await MainActor.run(body: { injected.appState[\.userData.lastSavedEventId] }) else {
            return
        }
        
        guard let savedEvent = events.first(where: { $0.id == lastSavedEventId }) else {
            await MainActor.run {
                injected.appState[\.userData.lastSavedEventId] = nil
            }
            return
        }
        
        if let appropriateFilter = injected.interactors.events.determineFilter(for: savedEvent, in: events) {
            await MainActor.run {
                selectedFilter = appropriateFilter
                injected.appState[\.userData.lastSavedEventId] = nil
            }
            print("HomeView - Switched to filter: \(appropriateFilter.rawValue) for saved event")
        } else {
            await MainActor.run {
                injected.appState[\.userData.lastSavedEventId] = nil
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        HomeView(triggerRefetch: .constant(false))
    }
    .inject(DIContainer(appState: AppState(), interactors: .stub))
}

