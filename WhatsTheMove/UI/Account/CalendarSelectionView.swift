//
//  CalendarSelectionView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/17/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import Combine

struct CalendarSelectionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.injected) private var injected: DIContainer
    
    @State private var selectedCalendarType: CalendarType = .apple
    @State private var calendarsState: Loadable<[CalendarInfo]> = .notRequested
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSignOutConfirmation: Bool = false
    @State private var isSigningOut: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F7F1")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    calendarTypeSelector
                    
                    if isCurrentProviderAuthenticated {
                        signOutButton
                    }
                    
                    content
                }
            }
            .navigationTitle("Select Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCalendars()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Sign Out from \(selectedCalendarType == .apple ? "Apple" : "Google") Calendar", role: .destructive) {
                    signOutFromProvider()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will disconnect your \(selectedCalendarType == .apple ? "Apple" : "Google") calendar and remove all synced events.")
            }
        }
    }
    
    @ViewBuilder private var content: some View {
        if selectedCalendarType == .google && !injected.interactors.calendar.isGoogleAuthenticated() {
            connectGoogleView()
        } else if selectedCalendarType == .apple && !injected.interactors.calendar.hasRequestedApplePermission() {
            connectAppleView()
        } else {
            switch calendarsState {
            case .notRequested:
                notRequestedView()
            case .isLoading:
                loadingView()
            case let .loaded(calendars):
                loadedView(calendars)
            case let .failed(error):
                failedView(error)
            }
        }
    }
}

// MARK: - Computed Properties

private extension CalendarSelectionView {
    
    var isCurrentProviderAuthenticated: Bool {
        switch selectedCalendarType {
        case .apple:
            let connectedType = injected.appState[\.userData.connectedCalendarType]
            return connectedType == .apple
        case .google:
            return injected.interactors.calendar.isGoogleAuthenticated()
        }
    }
}

// MARK: - Calendar Type Selector

private extension CalendarSelectionView {
    
    var calendarTypeSelector: some View {
        HStack(spacing: 0) {
            calendarTypeButton(type: .apple, title: "Apple Calendar")
            calendarTypeButton(type: .google, title: "Google Calendar")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    func calendarTypeButton(type: CalendarType, title: String) -> some View {
        Button {
            selectedCalendarType = type
            loadCalendars()
        } label: {
            Text(title)
                .font(.rubik(.medium, size: 14))
                .foregroundColor(selectedCalendarType == type ? .white : Color(hex: "11104B"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedCalendarType == type ? Color(hex: "4B7BE2") : Color.white)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    var signOutButton: some View {
        Button {
            showSignOutConfirmation = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14))
                
                Text("Sign Out from \(selectedCalendarType == .apple ? "Apple" : "Google") Calendar")
                    .font(.rubik(.medium, size: 14))
            }
            .foregroundColor(Color(hex: "F25454"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "F25454"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .disabled(isSigningOut)
        .opacity(isSigningOut ? 0.6 : 1.0)
    }
}

// MARK: - Loading Content

private extension CalendarSelectionView {
    
    func notRequestedView() -> some View {
        Text("")
    }
    
    func connectAppleView() -> some View {
        VStack(spacing: 30) {
            VStack(spacing: 15) {
                
                
                
            }
            
            CalendarConnectButton(
                iconName: "apple",
                title: "Connect Apple Calendar",
                action: { connectAppleCalendar() }
            )
            .padding(.horizontal, 40)

            Text("Grant access to your Apple Calendar to sync events")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }
    
    func connectGoogleView() -> some View {
        VStack(spacing: 30) {
            
            CalendarConnectButton(
                iconName: "google",
                title: "Connect Google Calendar",
                action: { connectGoogleCalendar() }
            )
            .padding(.horizontal, 40)
            
            Text("Sign in with your Google account to sync events with Google Calendar")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }
    
    func loadingView() -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "4B7BE2")))
                .scaleEffect(1.5)
            
            Text("Loading calendars...")
                .font(.rubik(.regular, size: 16))
                .foregroundColor(Color(hex: "55564F"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func failedView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "F25454"))
            
            Text("Failed to load calendars")
                .font(.rubik(.semiBold, size: 18))
                .foregroundColor(Color(hex: "11104B"))
            
            Text(error.localizedDescription)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                loadCalendars()
            } label: {
                Text("Try Again")
                    .font(.rubik(.medium, size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "4B7BE2"))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Displaying Content

private extension CalendarSelectionView {
    
    func loadedView(_ calendars: [CalendarInfo]) -> some View {
        ScrollView {
            if calendars.isEmpty {
                emptyStateView()
            } else {
                LazyVStack(spacing: 1) {
                    ForEach(groupedCalendars(calendars), id: \.key) { source, calendars in
                        Section {
                            ForEach(calendars) { calendar in
                                calendarRow(calendar)
                            }
                        } header: {
                            sectionHeader(source)
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
        .scrollIndicators(.hidden)
    }
    
    func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "55564F"))
            
            Text("No Calendars Found")
                .font(.rubik(.semiBold, size: 18))
                .foregroundColor(Color(hex: "11104B"))
            
            Text("Please create a calendar in your system settings first.")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.rubik(.medium, size: 11))
            .foregroundColor(Color(hex: "55564F"))
            .textCase(.uppercase)
            .kerning(0.44)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 15)
            .padding(.bottom, 5)
    }
    
    func calendarRow(_ calendar: CalendarInfo) -> some View {
        Button {
            selectCalendar(calendar)
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(calendar.color)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(calendar.title)
                        .font(.rubik(.medium, size: 15))
                        .foregroundColor(Color(hex: "11104B"))
                    
                    Text(calendar.source)
                        .font(.rubik(.regular, size: 13))
                        .foregroundColor(Color(hex: "55564F"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "11104B"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
        }
        .buttonStyle(.plain)
    }
    
    func groupedCalendars(_ calendars: [CalendarInfo]) -> [(key: String, value: [CalendarInfo])] {
        let grouped = Dictionary(grouping: calendars) { $0.source }
        return grouped.sorted { $0.key < $1.key }
    }
}

// MARK: - Side Effects

private extension CalendarSelectionView {
    
    func loadCalendars() {
        if selectedCalendarType == .google && !injected.interactors.calendar.isGoogleAuthenticated() {
            calendarsState = .notRequested
            return
        }
        
        if selectedCalendarType == .apple && !injected.interactors.calendar.hasRequestedApplePermission() {
            calendarsState = .notRequested
            return
        }
        
        calendarsState = .isLoading(last: nil, cancelBag: CancelBag())
        
        Task {
            do {
                let calendars = try await injected.interactors.calendar.getAvailableCalendars(for: selectedCalendarType)
                await MainActor.run {
                    calendarsState = .loaded(calendars)
                }
            } catch {
                await MainActor.run {
                    calendarsState = .failed(error)
                }
            }
        }
    }
    
    func connectAppleCalendar() {
        calendarsState = .isLoading(last: nil, cancelBag: CancelBag())
        
        Task {
            do {
                print("CalendarSelectionView - Requesting Apple Calendar permission")
                let granted = try await injected.interactors.calendar.requestCalendarPermission()
                
                if granted {
                    print("CalendarSelectionView - Permission granted, loading calendars")
                    let calendars = try await injected.interactors.calendar.getAvailableCalendars(for: .apple)
                    await MainActor.run {
                        calendarsState = .loaded(calendars)
                    }
                } else {
                    print("CalendarSelectionView - Permission denied")
                    await MainActor.run {
                        calendarsState = .notRequested
                        errorMessage = "Calendar permission was denied. Please enable it in Settings."
                        showError = true
                    }
                }
            } catch {
                print("CalendarSelectionView - Failed to request permission: \(error)")
                await MainActor.run {
                    calendarsState = .notRequested
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    func connectGoogleCalendar() {
        calendarsState = .isLoading(last: nil, cancelBag: CancelBag())
        
        Task {
            do {
                print("CalendarSelectionView - Connecting to Google Calendar")
                let calendars = try await injected.interactors.calendar.getAvailableCalendars(for: .google)
                await MainActor.run {
                    calendarsState = .loaded(calendars)
                }
            } catch {
                print("CalendarSelectionView - Failed to connect: \(error)")
                await MainActor.run {
                    calendarsState = .notRequested
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    func selectCalendar(_ calendar: CalendarInfo) {
        Task {
            do {
                switch calendar.type {
                case .apple:
                    try await injected.interactors.calendar.connectAppleCalendar(
                        calendarIdentifier: calendar.id,
                        calendarName: calendar.title
                    )
                case .google:
                    try await injected.interactors.calendar.connectGoogleCalendar(
                        calendarIdentifier: calendar.id,
                        calendarName: calendar.title
                    )
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    func signOutFromProvider() {
        isSigningOut = true
        
        Task {
            do {
                print("CalendarSelectionView - Signing out from \(selectedCalendarType) calendar")
                
                if selectedCalendarType == .google {
                    try await injected.interactors.calendar.signOutFromGoogle()
                }
                
                try await injected.interactors.calendar.disconnectCalendar()
                
                print("CalendarSelectionView - Sign out successful, checking auth status...")
                let stillAuthenticated = selectedCalendarType == .google ? 
                    injected.interactors.calendar.isGoogleAuthenticated() : false
                print("CalendarSelectionView - Still authenticated: \(stillAuthenticated)")
                
                await MainActor.run {
                    isSigningOut = false
                    calendarsState = .notRequested
                    dismiss()
                }
            } catch {
                print("CalendarSelectionView - Sign out failed: \(error)")
                await MainActor.run {
                    isSigningOut = false
                    errorMessage = "Failed to sign out: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    CalendarSelectionView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
