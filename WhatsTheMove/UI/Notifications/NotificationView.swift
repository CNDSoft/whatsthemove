//
//  NotificationView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/11/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import Combine

struct NotificationView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.injected) private var injected: DIContainer
    @State private var selectedFilter: NotificationFilter = .all
    @State private var isLoading: Bool = true
    
    private var notifications: [NotificationItem] {
        injected.appState[\.userData.notifications]
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            VStack(spacing: 5) {
                headerSection
                notificationContent
            }
        }
        .preferredColorScheme(.light)
        .task {
            await loadNotifications()
            isLoading = false
        }
        .onReceive(notificationTappedEventUpdate) { eventId in
            if eventId != nil {
                injected.appState[\.routing.notificationViewOpenedFrom] = nil
                dismiss()
            }
        }
    }
    
    private var notificationTappedEventUpdate: AnyPublisher<String?, Never> {
        injected.appState.updates(for: \.userData.notificationTappedEventId)
    }
    
    private var filteredNotifications: [NotificationItem] {
        switch selectedFilter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.isRead }
        case .event:
            return notifications.filter { $0.type == .event }
        case .registration:
            return notifications.filter { $0.type == .registration || $0.type == .deadline }
        }
    }
    
    private var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
}

// MARK: - Header Section

private extension NotificationView {
    
    var headerSection: some View {
        VStack(spacing: 10) {
            headerTopRow
            filterSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .clipShape(
            .rect(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
        )
    }
    
    var headerTopRow: some View {
        HStack {
            Text("Notifications")
                .font(.rubik(.extraBold, size: 20))
                .foregroundColor(Color(hex: "11104B"))
                .textCase(.uppercase)
            
            Spacer()
            
            closeButton
        }
    }
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "11104B"))
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    filterButton(for: filter)
                }
            }
        }
    }
    
    func filterButton(for filter: NotificationFilter) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Text(filter.rawValue)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                if filter == .unread && unreadCount > 0 {
                    unreadBadge
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .frame(height: 34)
            .background(
                selectedFilter == filter && filter != .unread
                    ? Color(hex: "E8E8FF")
                    : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .strokeBorder(
                        selectedFilter == filter || filter == .unread
                            ? Color.clear
                            : Color(hex: "EFEEE7"),
                        lineWidth: 1
                    )
            )
            .background(
                selectedFilter == filter && filter == .unread
                    ? Color(hex: "E8E8FF")
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 100))
        }
        .buttonStyle(.plain)
    }
    
    var unreadBadge: some View {
        Text("\(unreadCount)")
            .font(.rubik(.regular, size: 12))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(Color(hex: "11104B"))
            .clipShape(RoundedRectangle(cornerRadius: 100))
    }
}

// MARK: - Notification Content

private extension NotificationView {
    
    @ViewBuilder
    var notificationContent: some View {
        if isLoading {
            loadingView
        } else if filteredNotifications.isEmpty {
            emptyStateView
        } else {
            notificationListView
        }
    }
    
    var notificationListView: some View {
        ScrollView {
            VStack(spacing: 5) {
                let groupedNotifications = Dictionary(grouping: filteredNotifications) { notification -> String in
                    formatDateHeader(notification.timestamp)
                }
                
                let sortedKeys = groupedNotifications.keys.sorted { key1, key2 in
                    let date1 = parseDateHeader(key1)
                    let date2 = parseDateHeader(key2)
                    return date1 > date2
                }
                
                ForEach(sortedKeys, id: \.self) { dateKey in
                    VStack(spacing: 1) {
                        dateHeaderView(dateKey)
                        
                        if let notificationsForDate = groupedNotifications[dateKey] {
                            ForEach(notificationsForDate.sorted(by: { $0.timestamp > $1.timestamp })) { notification in
                                notificationRow(notification)
                                    .onTapGesture {
                                        handleNotificationTap(notification)
                                    }
                            }
                        }
                    }
                }
                
                if !filteredNotifications.isEmpty && selectedFilter != .unread && unreadCount > 0 {
                    markAllAsReadButton
                } else if !filteredNotifications.isEmpty && selectedFilter != .unread {
                }
            }
            .refreshable {
                await loadNotifications(isRefresh: true)
            }
        }
    }
    
    func dateHeaderView(_ dateString: String) -> some View {
        HStack {
            Text(dateString)
                .font(.rubik(.medium, size: 11))
                .foregroundColor(Color(hex: "55564F"))
                .textCase(.uppercase)
                .tracking(0.44)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .background(Color(hex: "F8F7F1"))
    }
    
    func notificationRow(_ notification: NotificationItem) -> some View {
        HStack(alignment: .top, spacing: 20) {
            HStack(alignment: .top, spacing: 10) {
                notificationIcon(notification.type)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.title)
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                        .lineLimit(1)
                    
                    Text(notification.message)
                        .font(.rubik(.regular, size: 13))
                        .foregroundColor(Color(hex: "55564F"))
                        .lineSpacing(0)
                    
                    if let actionText = notification.actionText {
                        Text(actionText)
                            .font(.rubik(.regular, size: 13))
                            .foregroundColor(Color(hex: "4B7BE2"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text(formatTime(notification.timestamp))
                .font(.rubik(.regular, size: 13))
                .foregroundColor(Color(hex: "55564F"))
                .opacity(0.5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
    
    func notificationIcon(_ type: NotificationType) -> some View {
        Image(type.iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundColor(Color(hex: "11104B"))
            .frame(width: 13, height: 13)
            .padding(.top, 3)
    }
    
    var markAllAsReadButton: some View {
        Button {
            markAllAsRead()
        } label: {
            HStack {
                Text("Mark all as read")
                    .font(.rubik(.regular, size: 13))
                    .foregroundColor(Color(hex: "4B7BE2"))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
        }
        .buttonStyle(.plain)
    }
    
    var loadingView: some View {
        VStack {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "11104B")))
                .scaleEffect(1.5)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var emptyStateView: some View {
        VStack(spacing: 15) {
            Spacer()
            
            ZStack {
                Image("bell")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(hex: "11104B").opacity(0.3))
                    .frame(width: 42.221, height: 44.16)
                
                Circle()
                    .fill(Color(hex: "11104B"))
                    .overlay(
                        Circle()
                            .strokeBorder(Color(hex: "F8F7F1"), lineWidth: 4)
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("0")
                            .font(.rubik(.bold, size: 18))
                            .foregroundColor(Color(hex: "F8F7F1"))
                            .textCase(.uppercase)
                    )
                    .offset(x: 15, y: 18)
            }
            .frame(width: 60, height: 60)
            
            Text("You don't have any\nunread notifications")
                .font(.rubik(.regular, size: 15))
                .foregroundColor(Color(hex: "55564F"))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helper Methods

private extension NotificationView {
    
    func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let notificationDate = calendar.startOfDay(for: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        
        if notificationDate == today {
            return "Today"
        } else if notificationDate == calendar.date(byAdding: .day, value: -1, to: today) {
            return "Yesterday"
        } else {
            return formatter.string(from: date)
        }
    }
    
    func parseDateHeader(_ header: String) -> Date {
        if header == "Today" {
            return Date()
        } else if header == "Yesterday" {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.date(from: header) ?? Date()
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Side Effects

private extension NotificationView {
    
    func loadNotifications(isRefresh: Bool = false) async {
        do {
            try await injected.interactors.notifications.loadNotifications()
        } catch {
            print("NotificationView - Error loading notifications: \(error)")
        }
    }
    
    func markAllAsRead() {
        Task {
            do {
                try await injected.interactors.notifications.markAllAsRead()
            } catch {
                print("NotificationView - Error marking all as read: \(error)")
            }
        }
    }
    
    func handleNotificationTap(_ notification: NotificationItem) {
        Task {
            await injected.interactors.notifications.handleNotificationTap(notification)
            
            if let eventId = notification.eventId {
                await MainActor.run {
                    let targetTab = determineTargetTab()
                    injected.appState[\.routing.selectedTab] = targetTab
                    
                    injected.appState[\.userData.notificationTappedEventId] = eventId
                    injected.appState[\.routing.notificationViewOpenedFrom] = nil
                    dismiss()
                }
            }
        }
    }
    
    func determineTargetTab() -> AppState.MainTab {
        let currentTab = injected.appState[\.routing.selectedTab]
        let notificationOpenedFrom = injected.appState[\.routing.notificationViewOpenedFrom]
        
        if currentTab == .profile {
            return .home
        }
        
        if let openedFrom = notificationOpenedFrom {
            return openedFrom == .home ? .home : .saved
        }
        
        return currentTab
    }
}

// MARK: - Previews

#Preview("Empty State") {
    NotificationView()
}

#Preview("With Notifications") {
    NotificationViewPreview()
}

#Preview("Unread Filter") {
    NotificationViewPreview(initialFilter: .unread)
}

#Preview("Event Filter") {
    NotificationViewPreview(initialFilter: .event)
}

private struct NotificationViewPreview: View {
    var initialFilter: NotificationFilter = .all
    
    var body: some View {
        NotificationViewWithMockData(initialFilter: initialFilter)
    }
}

private struct NotificationViewWithMockData: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: NotificationFilter
    @State private var notifications: [NotificationItem] = []
    
    init(initialFilter: NotificationFilter = .all) {
        _selectedFilter = State(initialValue: initialFilter)
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            VStack(spacing: 5) {
                headerSection
                notificationContent
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            loadMockData()
        }
    }
    
    private func loadMockData() {
        let calendar = Calendar.current
        let now = Date()
        
        notifications = [
            NotificationItem(
                userId: "user1",
                type: .event,
                title: "Event Reminder",
                message: "Summer Music Festival is tomorrow! Get ready for an amazing day.",
                actionText: "View Event",
                isRead: false,
                timestamp: calendar.date(byAdding: .hour, value: -2, to: now) ?? now
            ),
            NotificationItem(
                userId: "user1",
                type: .deadline,
                title: "Registration Deadline",
                message: "Only 2 days left to register for Tech Conference 2024.",
                actionText: "Register Now",
                isRead: false,
                timestamp: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            NotificationItem(
                userId: "user1",
                type: .registration,
                title: "Registration Confirmed",
                message: "Your registration for Food Festival has been confirmed.",
                actionText: "View Details",
                isRead: false,
                timestamp: calendar.date(byAdding: .hour, value: -5, to: now) ?? now
            ),
            NotificationItem(
                userId: "user1",
                type: .general,
                title: "Welcome to What's the Move",
                message: "Thanks for joining! Start by adding your first event.",
                actionText: "Add Now",
                isRead: true,
                timestamp: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            NotificationItem(
                userId: "user1",
                type: .event,
                title: "New Event Added",
                message: "Check out the Tech Meetup happening next week!",
                actionText: "View Event",
                isRead: true,
                timestamp: calendar.date(byAdding: .day, value: -2, to: now) ?? now
            )
        ]
    }
    
    private var filteredNotifications: [NotificationItem] {
        switch selectedFilter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.isRead }
        case .event:
            return notifications.filter { $0.type == .event }
        case .registration:
            return notifications.filter { $0.type == .registration || $0.type == .deadline }
        }
    }
    
    private var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            headerTopRow
            filterSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .clipShape(
            .rect(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
        )
    }
    
    private var headerTopRow: some View {
        HStack {
            Text("Notifications")
                .font(.rubik(.extraBold, size: 20))
                .foregroundColor(Color(hex: "11104B"))
                .textCase(.uppercase)
            
            Spacer()
            
            closeButton
        }
    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "11104B"))
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    filterButton(for: filter)
                }
            }
        }
    }
    
    private func filterButton(for filter: NotificationFilter) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Text(filter.rawValue)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                if filter == .unread && unreadCount > 0 {
                    unreadBadge
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .frame(height: 34)
            .background(
                selectedFilter == filter && filter != .unread
                    ? Color(hex: "E8E8FF")
                    : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .strokeBorder(
                        selectedFilter == filter || filter == .unread
                            ? Color.clear
                            : Color(hex: "EFEEE7"),
                        lineWidth: 1
                    )
            )
            .background(
                selectedFilter == filter && filter == .unread
                    ? Color(hex: "E8E8FF")
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 100))
        }
        .buttonStyle(.plain)
    }
    
    private var unreadBadge: some View {
        Text("\(unreadCount)")
            .font(.rubik(.regular, size: 12))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(Color(hex: "11104B"))
            .clipShape(RoundedRectangle(cornerRadius: 100))
    }
    
    @ViewBuilder
    private var notificationContent: some View {
        if filteredNotifications.isEmpty {
            emptyStateView
        } else {
            notificationListView
        }
    }
    
    private var notificationListView: some View {
        ScrollView {
            VStack(spacing: 5) {
                let groupedNotifications = Dictionary(grouping: filteredNotifications) { notification -> String in
                    formatDateHeader(notification.timestamp)
                }
                
                let sortedKeys = groupedNotifications.keys.sorted { key1, key2 in
                    let date1 = parseDateHeader(key1)
                    let date2 = parseDateHeader(key2)
                    return date1 > date2
                }
                
                ForEach(sortedKeys, id: \.self) { dateKey in
                    VStack(spacing: 1) {
                        dateHeaderView(dateKey)
                        
                        if let notificationsForDate = groupedNotifications[dateKey] {
                            ForEach(notificationsForDate.sorted(by: { $0.timestamp > $1.timestamp })) { notification in
                                notificationRow(notification)
                            }
                        }
                    }
                }
                
                if !filteredNotifications.isEmpty && selectedFilter != .unread && unreadCount > 0 {
                    markAllAsReadButton
                }
            }
        }
    }
    
    private func dateHeaderView(_ dateString: String) -> some View {
        HStack {
            Text(dateString)
                .font(.rubik(.medium, size: 11))
                .foregroundColor(Color(hex: "55564F"))
                .textCase(.uppercase)
                .tracking(0.44)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .background(Color(hex: "F8F7F1"))
    }
    
    private func notificationRow(_ notification: NotificationItem) -> some View {
        HStack(alignment: .top, spacing: 20) {
            HStack(alignment: .top, spacing: 10) {
                notificationIcon(notification.type)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.title)
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                        .lineLimit(1)
                    
                    Text(notification.message)
                        .font(.rubik(.regular, size: 13))
                        .foregroundColor(Color(hex: "55564F"))
                        .lineSpacing(0)
                    
                    if let actionText = notification.actionText {
                        Text(actionText)
                            .font(.rubik(.regular, size: 13))
                            .foregroundColor(Color(hex: "4B7BE2"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text(formatTime(notification.timestamp))
                .font(.rubik(.regular, size: 13))
                .foregroundColor(Color(hex: "55564F"))
                .opacity(0.5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
    
    private func notificationIcon(_ type: NotificationType) -> some View {
        Image(type.iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundColor(Color(hex: "11104B"))
            .frame(width: 13, height: 13)
            .padding(.top, 3)
    }
    
    private var markAllAsReadButton: some View {
        HStack {
            Text("Mark all as read")
                .font(.rubik(.regular, size: 13))
                .foregroundColor(Color(hex: "4B7BE2"))
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Spacer()
            
            ZStack {
                Image("bell")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(hex: "11104B").opacity(0.3))
                    .frame(width: 42.221, height: 44.16)
                
                Circle()
                    .fill(Color(hex: "11104B"))
                    .overlay(
                        Circle()
                            .strokeBorder(Color(hex: "F8F7F1"), lineWidth: 4)
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("0")
                            .font(.rubik(.bold, size: 18))
                            .foregroundColor(Color(hex: "F8F7F1"))
                            .textCase(.uppercase)
                    )
                    .offset(x: 15, y: 18)
            }
            .frame(width: 60, height: 60)
            
            Text("You don't have any\nunread notifications")
                .font(.rubik(.regular, size: 15))
                .foregroundColor(Color(hex: "55564F"))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let notificationDate = calendar.startOfDay(for: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        
        if notificationDate == today {
            return "Today"
        } else if notificationDate == calendar.date(byAdding: .day, value: -1, to: today) {
            return "Yesterday"
        } else {
            return formatter.string(from: date)
        }
    }
    
    private func parseDateHeader(_ header: String) -> Date {
        if header == "Today" {
            return Date()
        } else if header == "Yesterday" {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.date(from: header) ?? Date()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
}

