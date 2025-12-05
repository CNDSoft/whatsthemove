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
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                emptyStateContent
            }
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
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        } label: {
            Text(filter.rawValue)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(selectedFilter == filter ? Color(hex: "11104B") : Color(hex: "F8F7F1"))
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .frame(height: 34)
                .background(
                    selectedFilter == filter
                        ? Color.white
                        : Color.white.opacity(0.13)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State Content

private extension HomeView {
    
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
    
    var eventCountBadge: some View {
        Text("0")
            .font(.rubik(.bold, size: 18))
            .foregroundColor(Color(hex: "F8F7F1"))
            .frame(width: 32, height: 32)
            .background(Color(hex: "11104B"))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color(hex: "F8F7F1"), lineWidth: 4)
            )
    }
}

// MARK: - Previews

#Preview {
    HomeView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}

