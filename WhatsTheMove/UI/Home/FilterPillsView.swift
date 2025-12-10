//
//  FilterPillsView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/8/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct FilterPillsView<FilterType: RawRepresentable & Hashable & CaseIterable>: View where FilterType.RawValue == String {
    
    @Environment(\.injected) private var injected: DIContainer
    
    @Binding var selectedFilter: FilterType
    let events: [Event]
    let countProvider: (FilterType) -> Int
    let alwaysShowCount: Bool
    
    init(
        selectedFilter: Binding<FilterType>,
        events: [Event],
        countProvider: @escaping (FilterType) -> Int,
        alwaysShowCount: Bool = false
    ) {
        self._selectedFilter = selectedFilter
        self.events = events
        self.countProvider = countProvider
        self.alwaysShowCount = alwaysShowCount
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(FilterType.allCases), id: \.self) { filter in
                        filterPill(filter)
                            .id(filter)
                    }
                }
                .padding(.leading, 20)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .scrollDisabled(true)
            .clipped()
            .onChange(of: selectedFilter) { _, newFilter in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newFilter, anchor: .center)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo(selectedFilter, anchor: .center)
                }
            }
        }
        .frame(height: 34)
    }
}

// MARK: - Filter Pills

private extension FilterPillsView {
    
    func filterPill(_ filter: FilterType) -> some View {
        let count = countProvider(filter)
        let isSelected = selectedFilter == filter
        let shouldShowCount = alwaysShowCount || count > 0
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Text(filter.rawValue)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(isSelected ? Color(hex: "11104B") : Color(hex: "F8F7F1"))
                
                if shouldShowCount {
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
            .padding(.trailing, shouldShowCount ? 5 : 13)
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

// MARK: - Convenience Wrappers

struct EventFilterPillsView: View {
    @Environment(\.injected) private var injected: DIContainer
    @Binding var selectedFilter: EventFilter
    let events: [Event]
    
    var body: some View {
        FilterPillsView(
            selectedFilter: $selectedFilter,
            events: events,
            countProvider: { filter in
                injected.interactors.events.eventCount(events, for: filter)
            },
            alwaysShowCount: false
        )
    }
}

struct SavedFilterPillsView: View {
    @Environment(\.injected) private var injected: DIContainer
    @Binding var selectedFilter: SavedFilterType
    let events: [Event]
    let userId: String
    let starredIds: Set<String>
    
    var body: some View {
        FilterPillsView(
            selectedFilter: $selectedFilter,
            events: events,
            countProvider: { filter in
                injected.interactors.events.userEventCount(events, for: filter, userId: userId, starredIds: starredIds)
            },
            alwaysShowCount: true
        )
    }
}

// MARK: - Previews

#Preview("Home Filters") {
    EventFilterPillsView(
        selectedFilter: .constant(.tonight),
        events: []
    )
    .inject(DIContainer(appState: AppState(), interactors: .stub))
    .background(Color.blue)
}

#Preview("Saved Filters") {
    SavedFilterPillsView(
        selectedFilter: .constant(.allEvents),
        events: [],
        userId: "test-user-id",
        starredIds: []
    )
    .inject(DIContainer(appState: AppState(), interactors: .stub))
    .background(Color.blue)
}
