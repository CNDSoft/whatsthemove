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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F7F1")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    calendarTypeSelector
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
        }
    }
    
    @ViewBuilder private var content: some View {
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
}

// MARK: - Loading Content

private extension CalendarSelectionView {
    
    func notRequestedView() -> some View {
        Text("")
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
}

// MARK: - Previews

#Preview {
    CalendarSelectionView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
