//
//  SavedEventsView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/9/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import Combine

struct SavedEventsView: View {
    
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.injected) private var injected: DIContainer
    @State private var selectedFilter: SavedFilterType = .allEvents
    @State private var selectedCategory: EventCategory? = nil
    @State private var searchQuery: String = ""
    @State private var events: [Event] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var hasLoadedEvents: Bool = false
    @State private var showCategorySheet: Bool = false
    @State private var showNotificationsAlert: Bool = true
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
                
                if selectedFilter == .pastEvents && !filteredEvents.isEmpty {
                    pastEventsBanner
                }
                
                if hasEventsWithCategories {
                    categorySelector
                    
                    Divider()
                        .background(Color(hex: "55564F").opacity(0.2))
                }
                
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
        .sheet(isPresented: $showCategorySheet) {
            CategoriesView(
                selectedCategory: $selectedCategory,
                onDismiss: {
                    showCategorySheet = false
                },
                availableCategories: availableCategories,
                showAllCategoriesOption: true
            )
            .presentationDetents([.height(calculateSheetHeight())])
            .presentationDragIndicator(.visible)
            .presentationBackground(.white)
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
        .underDevelopmentAlert(isPresented: $showNotificationsAlert)
    }
    
    private var filteredEvents: [Event] {
        guard let currentUserId = injected.appState[\.userData.userId] else {
            return []
        }
        
        let starredIds = injected.appState[\.userData.starredEventIds]
        
        var filtered = injected.interactors.events.filterUserEvents(
            events,
            by: selectedFilter,
            userId: currentUserId,
            starredIds: starredIds
        )
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !searchQuery.isEmpty {
            filtered = injected.interactors.events.searchEvents(filtered, query: searchQuery)
        }
        
        return filtered
    }
    
    private var eventsInCurrentFilter: [Event] {
        guard let currentUserId = injected.appState[\.userData.userId] else {
            return []
        }
        
        let starredIds = injected.appState[\.userData.starredEventIds]
        
        var filtered = injected.interactors.events.filterUserEvents(
            events,
            by: selectedFilter,
            userId: currentUserId,
            starredIds: starredIds
        )
        
        if !searchQuery.isEmpty {
            filtered = injected.interactors.events.searchEvents(filtered, query: searchQuery)
        }
        
        return filtered
    }
    
    private var hasEventsWithCategories: Bool {
        return eventsInCurrentFilter.contains { $0.category != nil }
    }
    
    private var availableCategories: [EventCategory] {
        return injected.interactors.events.getAvailableCategories(from: eventsInCurrentFilter)
    }
    
    private var eventsUpdate: AnyPublisher<[Event], Never> {
        injected.appState.updates(for: \.userData.events)
    }
}

// MARK: - Header Section

private extension SavedEventsView {
    
    var headerSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                headerBackground(width: geometry.size.width)
                
                VStack(alignment: .leading, spacing: 20) {
                    titleView
                        .padding(.horizontal, 20)
                    filterSection
                }
                .padding(.top, 60)
                .frame(width: geometry.size.width, alignment: .leading)
            }
        }
        .frame(height: 250 - safeAreaInsets.top)
        .edgesIgnoringSafeArea(.top)
    }
    
    func headerBackground(width: CGFloat) -> some View {
        ZStack {
            Image("saved-events-header")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: 250)
                .clipped()
        }
        .frame(width: width, height: 250)
    }
    
    var titleView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MY SAVED")
                .font(.rubik(.extraBold, size: 30))
                .foregroundColor(.white)
                .textCase(.uppercase)
            Text("EVENTS")
                .font(.rubik(.extraBold, size: 30))
                .foregroundColor(.white)
                .textCase(.uppercase)
        }
        .lineSpacing(0)
    }
    
    var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchBar
            
            filterPillsContent
                .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    var filterPillsContent: some View {
        if let currentUserId = injected.appState[\.userData.userId] {
            let starredIds = injected.appState[\.userData.starredEventIds]
            
            SavedFilterPillsView(
                selectedFilter: $selectedFilter,
                events: events,
                userId: currentUserId,
                starredIds: starredIds
            )
        }
    }
    
    var searchBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "F8F7F1").opacity(0.7))
                
                ZStack(alignment: .leading) {
                    if searchQuery.isEmpty {
                        Text("Search events...")
                            .font(.rubik(.regular, size: 14))
                            .foregroundColor(Color(hex: "F8F7F1").opacity(0.7))
                    }
                    
                    TextField("", text: $searchQuery)
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "F8F7F1"))
                        .tint(Color(hex: "E7FF63"))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .padding(.leading, 15)
            .padding(.trailing, 6)
            
            Button {
                if !searchQuery.isEmpty {
                    searchQuery = ""
                }
            } label: {
                Image(systemName: searchQuery.isEmpty ? "magnifyingglass" : "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "E7FF63"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 6)
        }
        .frame(height: 46)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 400)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .padding(.horizontal, 20)
        )
        .animation(.easeInOut(duration: 0.2), value: searchQuery.isEmpty)
    }
}

// MARK: - Category Selector

private extension SavedEventsView {
    
    var categorySelector: some View {
        Button {
            showCategorySheet = true
        } label: {
            HStack {
                Text(selectedCategory?.rawValue ?? "All Categories")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "55564F"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Past Events Banner

private extension SavedEventsView {
    
    var pastEventsBanner: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Text("Showing your past events. These are events with dates that have already passed.")
                    .font(.rubik(.regular, size: 12))
                    .foregroundColor(Color(hex: "11104B"))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(hex: "E7FF63").opacity(0.3))
        }
    }
}

// MARK: - Event List Content

private extension SavedEventsView {
    
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
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable {
            await refreshEvents()
        }
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
    
    var emptyStateContent: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ticketIconWithBadge
            
            Text(emptyStateMessage)
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
    
    var emptyStateMessage: String {
        guard let currentUserId = injected.appState[\.userData.userId] else {
            return "Please log in to view your events"
        }
        
        let userEvents = events.filter { $0.userId == currentUserId }
        
        if userEvents.isEmpty {
            return "No events found - Start by adding your first event"
        }
        
        if selectedFilter == .pastEvents {
            return "You don't have any past events yet"
        }
        
        return "No events found. Try another filter or add some events"
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

private extension SavedEventsView {
    
    func loadEventsIfNeeded() async {
        guard !hasLoadedEvents else {
            print("SavedEventsView - Events already loaded, skipping")
            return
        }
        
        let cachedEvents = await MainActor.run {
            injected.appState[\.userData.events]
        }
        
        if !cachedEvents.isEmpty {
            print("SavedEventsView - Using \(cachedEvents.count) preloaded events from cache")
            events = cachedEvents
            hasLoadedEvents = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedEvents = try await injected.interactors.events.getAllEvents(forceReload: false)
            events = fetchedEvents
            isLoading = false
            hasLoadedEvents = true
            print("SavedEventsView - Loaded \(fetchedEvents.count) events")
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("SavedEventsView - Failed to load events: \(error.localizedDescription)")
        }
    }
    
    func refreshEvents() async {
        print("SavedEventsView - Refreshing events")
        
        do {
            let fetchedEvents = try await injected.interactors.events.getAllEvents(forceReload: true)
            events = fetchedEvents
            print("SavedEventsView - Refreshed \(fetchedEvents.count) events")
        } catch {
            errorMessage = error.localizedDescription
            print("SavedEventsView - Failed to refresh events: \(error.localizedDescription)")
        }
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
                
                print("SavedEventsView - Event deleted successfully: \(event.id)")
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = error.localizedDescription
                    eventToDelete = nil
                }
                print("SavedEventsView - Failed to delete event: \(error.localizedDescription)")
            }
        }
    }
    
    func calculateSheetHeight() -> CGFloat {
        let categoryCount = availableCategories.count + 1
        let topPadding: CGFloat = 10 + 19
        let dragIndicatorHeight: CGFloat = 5
        let categoryRowHeight: CGFloat = 40
        let categorySpacing: CGFloat = 19
        let bottomPadding: CGFloat = 20
        
        let totalHeight = topPadding + dragIndicatorHeight + (CGFloat(categoryCount) * categoryRowHeight) + (CGFloat(max(0, categoryCount - 1)) * categorySpacing) + bottomPadding
        
        return min(totalHeight, 500)
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
        
        let starredIds = await MainActor.run { injected.appState[\.userData.starredEventIds] }
        let appropriateFilter = injected.interactors.events.determineSavedFilter(for: savedEvent, starredIds: starredIds)
        
        await MainActor.run {
            selectedFilter = appropriateFilter
            injected.appState[\.userData.lastSavedEventId] = nil
        }
        print("SavedEventsView - Switched to filter: \(appropriateFilter.rawValue) for saved event")
    }
}

// MARK: - Previews

#Preview {
    let previewEvents = StubEventInteractor.previewEvents
    
    var previewAppState = AppState()
    previewAppState.userData.userId = "preview"
    previewAppState.userData.events = previewEvents
    previewAppState.userData.starredEventIds = Set([
        previewEvents[0].id,
        previewEvents[3].id,
        previewEvents[6].id
    ])
    
    return NavigationStack {
        SavedEventsView(triggerRefetch: .constant(false))
    }
    .inject(DIContainer(appState: previewAppState, interactors: .stub))
}
