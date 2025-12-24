//
//  EventDetailView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/8/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import Combine

struct EventDetailView: View {
    
    let event: Event
    var onEdit: ((Event) -> Void)? = nil
    var onDelete: ((Event) -> Void)? = nil
    
    @State private var isStarred: Bool = false
    @State private var showAddToCalendarAlert: Bool = false
    @State private var showActionsSheet: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.injected) private var injected: DIContainer
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color(hex: "F8F7F1")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        headerImageSection
                        contentSection
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                navigationBar(safeAreaTop: geometry.safeAreaInsets.top)
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .onReceive(starredEventsUpdate) { starredIds in
            isStarred = starredIds.contains(event.id)
        }
        .onAppear {
            isStarred = injected.interactors.users.isEventStarred(eventId: event.id)
        }
        .sheet(isPresented: $showActionsSheet) {
            EventActionsSheet(
                onEditTapped: {
                    showActionsSheet = false
                    onEdit?(event)
                },
                onDeleteTapped: {
                    showActionsSheet = false
                    onDelete?(event)
                }
            )
            .presentationDetents([.height(113)])
            .presentationDragIndicator(.visible)
            .presentationBackground(.white)
        }
        .underDevelopmentAlert(isPresented: $showAddToCalendarAlert)
    }
    
    private var starredEventsUpdate: AnyPublisher<Set<String>, Never> {
        injected.appState.updates(for: \.userData.starredEventIds)
    }
}

// MARK: - Navigation Bar

private extension EventDetailView {
    
    func navigationBar(safeAreaTop: CGFloat) -> some View {
        HStack {
            backButton
            Spacer()
            /*
            if isCurrentUserEventOwner {
                moreButton
            }*/
        }
        .padding(.horizontal, 20)
        .padding(.top, safeAreaTop + 10)
        .frame(maxWidth: .infinity, alignment: .top)
    }
    
    var isCurrentUserEventOwner: Bool {
        guard let currentUserId = injected.appState[\.userData.userId] else {
            return false
        }
        return currentUserId == event.userId
    }
    
    var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    var moreButton: some View {
        Button {
            showActionsSheet = true
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Header Image Section

private extension EventDetailView {
    
    var headerImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            headerImage
            
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            starButton
                .padding(20)
        }
        .frame(height: 280)
    }
    
    var headerImage: some View {
        Group {
            if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    imagePlaceholder
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(height: 280)
        .clipped()
    }
    
    var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(hex: "E8E8FF"))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "55564F").opacity(0.3))
            )
    }
    
    var starButton: some View {
        let starImageName = isStarred ? "star-enabled" : "star-disabled"
        
        return Button {
            Task {
                try? await injected.interactors.users.toggleStarredEvent(eventId: event.id)
            }
        } label: {
            Image(starImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Content Section

private extension EventDetailView {
    
    var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            titleAndTagsSection
            dateTimeSection
            
            if let location = event.location, !location.isEmpty {
                locationSection(location)
            }
            
            if event.urlLink != nil {
                urlSection
            }
            
            admissionSection
            
            if event.requiresRegistration {
                registrationSection
            }
            
            if let notes = event.notes, !notes.isEmpty {
                notesSection(notes)
            }
            
            actionButtonsSection
        }
        .padding(20)
        .padding(.bottom, 40)
        .background(Color(hex: "F8F7F1"))
    }
}

// MARK: - Title and Tags

private extension EventDetailView {
    
    var titleAndTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(event.name.uppercased())
                .font(.rubik(.bold, size: 24))
                .foregroundColor(Color(hex: "11104B"))
            
            tagsRow
        }
    }
    
    var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                statusTag
                admissionTag
            }
        }
    }
    
    var statusTag: some View {
        let config = statusConfig(for: event.status)
        
        return HStack(spacing: 6) {
            Circle()
                .fill(config.dotColor)
                .frame(width: 6, height: 6)
            
            Text(event.status.rawValue)
                .font(.rubik(.medium, size: 14))
                .foregroundColor(config.textColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(config.backgroundColor)
        .clipShape(Capsule())
    }
    
    var admissionTag: some View {
        let text: String
        if event.admission == .free {
            text = "Free"
        } else if let amount = event.admissionAmount {
            text = "\(Currency.symbol)\(Int(amount))"
        } else {
            text = "Paid"
        }
        
        return Text(text)
            .font(.rubik(.medium, size: 14))
            .foregroundColor(Color(hex: "55564F"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "F8F7F1"))
            .overlay(
                Capsule()
                    .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
    
    func statusConfig(for status: EventStatus) -> (backgroundColor: Color, textColor: Color, dotColor: Color) {
        switch status {
        case .interested:
            return (Color(hex: "FFF0FB"), Color(hex: "B86AA1"), Color(hex: "B86AA1"))
        case .going:
            return (Color(hex: "45DFAE").opacity(0.1), Color(hex: "2D9674"), Color(hex: "2D9674"))
        case .waitlisted:
            return (Color(hex: "FA7929").opacity(0.1), Color(hex: "FA7929"), Color(hex: "FA7929"))
        }
    }
}

// MARK: - Date Time Section

private extension EventDetailView {
    
    var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Date & Time")
            
            HStack(spacing: 16) {
                dateInfoCard
                if event.startTime != nil && event.endTime != nil {
                    timeInfoCard
                }
            }
        }
    }
    
    var dateInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "11104B"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedFullDate)
                    .font(.rubik(.medium, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Text(formattedDayOfWeek)
                    .font(.rubik(.regular, size: 12))
                    .foregroundColor(Color(hex: "55564F"))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    var timeInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "11104B"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedStartTime)
                    .font(.rubik(.medium, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Text("to \(formattedEndTime)")
                    .font(.rubik(.regular, size: 12))
                    .foregroundColor(Color(hex: "55564F"))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Location Section

private extension EventDetailView {
    
    func locationSection(_ location: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Location")
            
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "11104B"))
                
                Text(location)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                    .lineLimit(2)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "55564F"))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - URL Section

private extension EventDetailView {
    
    var urlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Event Link")
            
            if let urlString = event.urlLink, let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: 12) {
                        Image(systemName: "link")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "11104B"))
                        
                        Text(urlString)
                            .font(.rubik(.regular, size: 14))
                            .foregroundColor(Color(hex: "11104B"))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "55564F"))
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Admission Section

private extension EventDetailView {
    
    var admissionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Admission")
            
            HStack(spacing: 12) {
                Image(systemName: "ticket")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "11104B"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(admissionText)
                        .font(.rubik(.medium, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                    
                    Text(event.admission == .free ? "No ticket required" : "Ticket purchase required")
                        .font(.rubik(.regular, size: 12))
                        .foregroundColor(Color(hex: "55564F"))
                }
                
                Spacer()
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    var admissionText: String {
        if event.admission == .free {
            return "Free Entry"
        } else if let amount = event.admissionAmount {
            return "\(Currency.symbol)\(Int(amount))"
        } else {
            return "Paid"
        }
    }
}

// MARK: - Registration Section

private extension EventDetailView {
    
    var registrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Registration")
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "pencil.and.list.clipboard")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "FA7929"))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Registration Required")
                            .font(.rubik(.medium, size: 14))
                            .foregroundColor(Color(hex: "11104B"))
                        
                        if let deadline = event.registrationDeadline {
                            Text("Deadline: \(formattedDeadline(deadline))")
                                .font(.rubik(.regular, size: 12))
                                .foregroundColor(Color(hex: "55564F"))
                        }
                    }
                    
                    Spacer()
                }
                .padding(14)
                
                if let deadline = event.registrationDeadline {
                    let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
                    
                    if daysUntil >= 0 && daysUntil <= 7 {
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "F25454"))
                            
                            Text(registrationWarningText(daysUntil: daysUntil))
                                .font(.rubik(.medium, size: 12))
                                .foregroundColor(Color(hex: "F25454"))
                            
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(hex: "F25454").opacity(0.05))
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    func formattedDeadline(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    func registrationWarningText(daysUntil: Int) -> String {
        switch daysUntil {
        case 0:
            return "Registration closes today!"
        case 1:
            return "Registration closes tomorrow!"
        default:
            return "Registration closes in \(daysUntil) days"
        }
    }
}

// MARK: - Notes Section

private extension EventDetailView {
    
    func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Notes")
            
            Text(notes)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F"))
                .lineSpacing(4)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
        }
    }
}

// MARK: - Action Buttons Section

private extension EventDetailView {
    
    var actionButtonsSection: some View {
        VStack(spacing: 12) {
            addToCalendarButton
            
            if event.urlLink != nil {
                openLinkButton
            }
        }
        .padding(.top, 8)
    }
    
    var addToCalendarButton: some View {
        Button {
            showAddToCalendarAlert = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 18))
                
                Text("Add to Calendar")
                    .font(.rubik(.medium, size: 16))
            }
            .foregroundColor(Color(hex: "11104B"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "E8E8FF"))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    var openLinkButton: some View {
        Group {
            if let urlString = event.urlLink, let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 18))
                        
                        Text("Open Event Link")
                            .font(.rubik(.medium, size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "11104B"))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Helpers

private extension EventDetailView {
    
    func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.rubik(.bold, size: 12))
            .foregroundColor(Color(hex: "55564F"))
            .kerning(1)
    }
    
    var formattedFullDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: event.eventDate)
    }
    
    var formattedDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: event.eventDate)
    }
    
    var formattedStartTime: String {
        guard let startTime = event.startTime else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
    
    var formattedEndTime: String {
        guard let endTime = event.endTime else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: endTime)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        EventDetailView(
            event: Event(
                userId: "test",
                name: "Summer Music Festival",
                eventDate: Date(),
                startTime: Date(),
                endTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(),
                urlLink: "https://example.com/event",
                admission: .paid,
                admissionAmount: 25,
                requiresRegistration: true,
                registrationDeadline: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                category: .music,
                notes: "Bring your own blanket and snacks. No outside drinks allowed. Parking available on site.",
                location: "Central Park, New York, NY",
                status: .going
            )
        )
    }
}
