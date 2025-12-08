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
    @State private var errorMessage: String?
    
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
        .onAppear {
            loadEvents()
        }
    }
    
    private var filteredEvents: [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedFilter {
        case .tonight:
            return events.filter { event in
                calendar.isDateInToday(event.eventDate)
            }
        case .thisWeekend:
            let weekday = calendar.component(.weekday, from: now)
            let daysUntilSaturday = (7 - weekday) % 7
            let daysUntilSunday = daysUntilSaturday + 1
            
            guard let saturday = calendar.date(byAdding: .day, value: daysUntilSaturday == 0 ? 0 : daysUntilSaturday, to: now),
                  let sunday = calendar.date(byAdding: .day, value: daysUntilSunday == 1 ? 1 : daysUntilSunday, to: now) else {
                return []
            }
            
            return events.filter { event in
                calendar.isDate(event.eventDate, inSameDayAs: saturday) ||
                calendar.isDate(event.eventDate, inSameDayAs: sunday)
            }
        case .nextWeek:
            guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: now),
                  let startOfNextWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: nextWeekStart)),
                  let endOfNextWeek = calendar.date(byAdding: .day, value: 6, to: startOfNextWeek) else {
                return []
            }
            
            return events.filter { event in
                event.eventDate >= startOfNextWeek && event.eventDate <= endOfNextWeek
            }
        case .thisMonth:
            return events.filter { event in
                calendar.isDate(event.eventDate, equalTo: now, toGranularity: .month)
            }
        case .recentlySaved:
            return events.sorted { $0.createdAt > $1.createdAt }
        }
    }
}

// MARK: - Event Filter

extension HomeView {
    
    enum EventFilter: String, CaseIterable {
        case tonight = "Tonight"
        case thisWeekend = "This Weekend"
        case nextWeek = "Next Week"
        case thisMonth = "This Month"
        case recentlySaved = "Recently Saved"
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
        .frame(height: 250).edgesIgnoringSafeArea(.top)
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
            
            filterPillsScrollView
        }.padding(.leading, 20)
    }
    
    var filterPillsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(EventFilter.allCases, id: \.self) { filter in
                    filterPill(filter)
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    func filterPill(_ filter: EventFilter) -> some View {
        let count = eventCount(for: filter)
        let isSelected = selectedFilter == filter
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Text(filter.rawValue)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(isSelected ? Color(hex: "11104B") : Color(hex: "F8F7F1"))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.rubik(.regular, size: 12))
                        .foregroundColor(Color(hex: "11104B"))
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(isSelected ? Color(hex: "E8E8FF") : Color(hex: "E7FF63"))
                        .clipShape(Capsule())
                }
            }
            .padding(.leading, 13)
            .padding(.trailing, count > 0 ? 5 : 13)
            .padding(.vertical, 5)
            .frame(height: 34)
            .background(
                isSelected
                    ? Color.white
                    : Color.white.opacity(0.13)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
                }
            }
            .padding(.bottom, 100)
        }
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
    
    func loadEvents() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedEvents = try await injected.interactors.events.getAllEvents()
                await MainActor.run {
                    events = fetchedEvents
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    print("HomeView - Failed to load events: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func eventCount(for filter: EventFilter) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        switch filter {
        case .tonight:
            return events.filter { calendar.isDateInToday($0.eventDate) }.count
        case .thisWeekend:
            let weekday = calendar.component(.weekday, from: now)
            let daysUntilSaturday = (7 - weekday) % 7
            let daysUntilSunday = daysUntilSaturday + 1
            
            guard let saturday = calendar.date(byAdding: .day, value: daysUntilSaturday == 0 ? 0 : daysUntilSaturday, to: now),
                  let sunday = calendar.date(byAdding: .day, value: daysUntilSunday == 1 ? 1 : daysUntilSunday, to: now) else {
                return 0
            }
            
            return events.filter { event in
                calendar.isDate(event.eventDate, inSameDayAs: saturday) ||
                calendar.isDate(event.eventDate, inSameDayAs: sunday)
            }.count
        case .nextWeek:
            guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: now),
                  let startOfNextWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: nextWeekStart)),
                  let endOfNextWeek = calendar.date(byAdding: .day, value: 6, to: startOfNextWeek) else {
                return 0
            }
            
            return events.filter { event in
                event.eventDate >= startOfNextWeek && event.eventDate <= endOfNextWeek
            }.count
        case .thisMonth:
            return events.filter { calendar.isDate($0.eventDate, equalTo: now, toGranularity: .month) }.count
        case .recentlySaved:
            return events.count
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        HomeView()
    }
    .inject(DIContainer(appState: AppState(), interactors: .stub))
}

