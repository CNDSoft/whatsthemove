//
//  EventCardView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import Combine

struct EventCardView: View {
    
    let event: Event
    var showActions: Bool = false
    var onEdit: ((Event) -> Void)? = nil
    var onDelete: ((Event) -> Void)? = nil
    
    @State private var showRegistrationDeadline: Bool = false
    @State private var showNoteOverlay: Bool = false
    @State private var isStarred: Bool = false
    @State private var showMoreAlert: Bool = false
    @State private var showActionsSheet: Bool = false
    @State private var showCalendarAlert: Bool = false
    @State private var showDismissWarningAlert: Bool = false
    @Environment(\.injected) private var injected: DIContainer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            eventInfoRow
            actionButtonsRow
            registrationWarning
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
        .fullScreenCover(isPresented: $showNoteOverlay) {
            noteOverlayView
        }
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
        .underDevelopmentAlert(isPresented: $showMoreAlert)
        .underDevelopmentAlert(isPresented: $showCalendarAlert)
        .underDevelopmentAlert(isPresented: $showDismissWarningAlert)
    }
    
    private var starredEventsUpdate: AnyPublisher<Set<String>, Never> {
        injected.appState.updates(for: \.userData.starredEventIds)
    }
}

// MARK: - Event Info Row

private extension EventCardView {
    
    var eventInfoRow: some View {
        HStack(alignment: .top, spacing: 13) {
            eventImage
            eventDetails
            Spacer(minLength: 0)
            moreButton
        }
    }
    
    var eventImage: some View {
        ZStack(alignment: .topLeading) {
            if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } placeholder: {
                    imagePlaceholder
                }
            } else {
                imagePlaceholder
            }
            
            starButton
                .padding(7)
        }
        .frame(width: 100, height: 100)
    }
    
    var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(hex: "F8F7F1"))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "55564F").opacity(0.5))
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
                .frame(width: 27, height: 27)
        }
        .buttonStyle(.plain)
    }
    
    var eventDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(event.name.uppercased())
                .font(.rubik(.bold, size: 18))
                .foregroundColor(Color(hex: "11104B"))
            
            tagsRow
            dateRow
            
            if let location = event.location, !location.isEmpty {
                locationRow(location)
            }
        }
        .padding(.bottom, 10)
    }
    
    var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                statusTag
                
                if event.requiresRegistration {
                    registrationTag
                }
                
                if let category = event.category {
                    categoryTag(category)
                }
                
                admissionTag
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var statusTag: some View {
        let config = statusConfig(for: event.status)
        
        return HStack(spacing: 6) {
            Circle()
                .fill(config.dotColor)
                .frame(width: 5, height: 5)
            
            Text(event.status.rawValue)
                .font(.rubik(.regular, size: 12))
                .foregroundColor(config.textColor)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(config.backgroundColor)
        .clipShape(Capsule())
    }
    
    var registrationTag: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showRegistrationDeadline.toggle()
            }
        } label: {
            HStack(spacing: 5) {
                Text(registrationTagText)
                    .font(.rubik(.regular, size: 12))
                    .foregroundColor(Color(hex: "FA7929"))
                
                if !showRegistrationDeadline {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "FA7929"))
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color(hex: "FA7929").opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    var registrationTagText: String {
        if showRegistrationDeadline, let deadline = event.registrationDeadline {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Register by \(formatter.string(from: deadline))"
        }
        return "Registration"
    }
    
    func categoryTag(_ category: EventCategory) -> some View {
        HStack(spacing: 6) {
            Image(category.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
            
            Text(category.rawValue)
                .font(.rubik(.regular, size: 12))
                .foregroundColor(Color(hex: "55564F"))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color(hex: "F8F7F1"))
        .clipShape(Capsule())
    }
    
    var admissionTag: some View {
        let text: String
        if event.admission == .free {
            text = "Free"
        } else if let amount = event.admissionAmount {
            text = "$\(Int(amount))"
        } else {
            text = "Paid"
        }
        
        return Text(text)
            .font(.rubik(.regular, size: 12))
            .foregroundColor(Color(hex: "55564F"))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color(hex: "F8F7F1"))
            .clipShape(Capsule())
    }
    
    var dateRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "55564F"))
            
            HStack(spacing: 7) {
                Text(formattedDate)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                
                Circle()
                    .fill(Color(hex: "55564F"))
                    .frame(width: 3, height: 3)
                
                Text(formattedTime)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
            }
        }
    }
    
    func locationRow(_ location: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.circle")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "55564F"))
            
            Text(location)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F"))
                .lineLimit(1)
        }
    }
    
    var moreButton: some View {
        Button {
            if showActions {
                showActionsSheet = true
            } else {
                showMoreAlert = true
            }
        } label: {
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color(hex: "11104B").opacity(0.5))
                        .frame(width: 2.3, height: 2.3)
                }
            }
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: event.eventDate)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: event.startTime).lowercased()
    }
}

// MARK: - Action Buttons

private extension EventCardView {
    
    var actionButtonsRow: some View {
        HStack(spacing: 5) {
            if hasNotes {
                noteButton
            }
            calendarButton
            viewDetailsButton
        }
    }
    
    var hasNotes: Bool {
        if let notes = event.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }
    
    var noteButton: some View {
        Button {
            showNoteOverlay = true
        } label: {
            HStack(spacing: 8) {
                Image("note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                
                Text("Note")
                    .font(.rubik(.regular, size: 12))
            }
            .foregroundColor(Color(hex: "11104B"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(hex: "F8F7F1"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    var calendarButton: some View {
        Button {
            showCalendarAlert = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14))
                
                Text("Calendar")
                    .font(.rubik(.regular, size: 12))
            }
            .foregroundColor(Color(hex: "11104B"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(hex: "F8F7F1"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    var viewDetailsButton: some View {
        NavigationLink(value: event) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 14))
                
                Text("View details")
                    .font(.rubik(.regular, size: 12))
            }
            .foregroundColor(Color(hex: "11104B"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(hex: "E8E8FF"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Registration Warning

private extension EventCardView {
    
    @ViewBuilder
    var registrationWarning: some View {
        if event.requiresRegistration, let deadline = event.registrationDeadline {
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
            
            if daysUntil >= 0 && daysUntil <= 7 {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "F25454"))
                    
                    Text(registrationDeadlineText(daysUntil: daysUntil))
                        .font(.rubik(.regular, size: 12))
                        .foregroundColor(Color(hex: "F25454"))
                    
                    Spacer()
                    
                    Button {
                        showDismissWarningAlert = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(Color(hex: "F25454"))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "F25454").opacity(0.05))
                .clipShape(Capsule())
            }
        }
    }
    
    func registrationDeadlineText(daysUntil: Int) -> String {
        switch daysUntil {
        case 0:
            return "Register today"
        case 1:
            return "Register by tomorrow"
        default:
            return "Register in \(daysUntil) days"
        }
    }
}

// MARK: - Note Overlay

private extension EventCardView {
    
    var noteOverlayView: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                if let notes = event.notes {
                    Text(notes)
                        .font(.rubik(.regular, size: 24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button {
                    showNoteOverlay = false
                } label: {
                    Text("Close")
                        .font(.rubik(.regular, size: 18))
                        .foregroundColor(.white)
                        .underline()
                }
                .buttonStyle(.plain)
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    EventCardView(
        event: Event(
            userId: "test",
            name: "Cooking Class",
            eventDate: Date(),
            startTime: Date(),
            endTime: Date(),
            admission: .free,
            requiresRegistration: true,
            registrationDeadline: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            category: .food,
            notes: "Going with John, Liz and Samantha",
            location: "Central Park, New York, NY",
            status: .interested
        )
    )
}



