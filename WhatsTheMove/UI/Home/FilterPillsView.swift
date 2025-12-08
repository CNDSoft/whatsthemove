//
//  FilterPillsView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/8/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct FilterPillsView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    
    @Binding var selectedFilter: EventFilter
    let events: [Event]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EventFilter.allCases, id: \.self) { filter in
                        filterPill(filter)
                            .id(filter)
                    }
                }
                .padding(.leading, 20)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
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

// MARK: - Helper Methods

private extension FilterPillsView {
    
    func eventCount(for filter: EventFilter) -> Int {
        injected.interactors.events.eventCount(events, for: filter)
    }
}

// MARK: - Previews

#Preview {
    FilterPillsView(
        selectedFilter: .constant(.tonight),
        events: []
    )
    .inject(DIContainer(appState: AppState(), interactors: .stub))
    .background(Color.blue)
}
