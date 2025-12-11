//
//  AccountView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/11/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct AccountView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var isSigningOut: Bool = false
    
    @State private var calendarConnected: Bool = false
    @State private var includeSourceLinks: Bool = true
    @State private var eventRemindersEnabled: Bool = true
    @State private var eventRemindersExpanded: Bool = true
    @State private var reminderWeekBefore: Bool = false
    @State private var reminderDayBefore: Bool = true
    @State private var reminder3Hours: Bool = true
    @State private var reminderInterestedDayBefore: Bool = true
    @State private var registrationDeadlinesEnabled: Bool = true
    @State private var systemNotificationsEnabled: Bool = true
    @State private var analyticsEnabled: Bool = false
    
    @State private var showNotificationAlert: Bool = false
    @State private var showCalendarAlert: Bool = false
    @State private var showEditProfileAlert: Bool = false
    @State private var showSourceLinksAlert: Bool = false
    @State private var showRegistrationAlert: Bool = false
    @State private var showSystemNotificationsAlert: Bool = false
    @State private var showAnalyticsAlert: Bool = false
    @State private var showFeedbackAlert: Bool = false
    @State private var showRateAppAlert: Bool = false
    @State private var showPrivacyPolicyAlert: Bool = false
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            content
        }
        .underDevelopmentAlert(isPresented: $showNotificationAlert)
        .underDevelopmentAlert(isPresented: $showCalendarAlert)
        .underDevelopmentAlert(isPresented: $showEditProfileAlert)
        .underDevelopmentAlert(isPresented: $showSourceLinksAlert)
        .underDevelopmentAlert(isPresented: $showRegistrationAlert)
        .underDevelopmentAlert(isPresented: $showSystemNotificationsAlert)
        .underDevelopmentAlert(isPresented: $showAnalyticsAlert)
        .underDevelopmentAlert(isPresented: $showFeedbackAlert)
        .underDevelopmentAlert(isPresented: $showRateAppAlert)
        .underDevelopmentAlert(isPresented: $showPrivacyPolicyAlert)
    }
}

// MARK: - Content

private extension AccountView {
    
    var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                
                VStack(spacing: 5) {
                    profileSection
                    calendarExportSection
                    notificationsSection
                    dataPrivacySection
                    supportInfoSection
                    signOutSection
                    footer
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Header Section

private extension AccountView {
    
    var header: some View {
        ZStack(alignment: .topLeading) {
            headerBackground
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("ACCOUNT")
                        .font(.rubik(.extraBold, size: 30))
                        .foregroundColor(.white)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    Button {
                        showNotificationAlert = true
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "11104B"))
                            .frame(width: 38, height: 38)
                            .background(Color(hex: "E7FF63"))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(height: 90)
    }
    
    var headerBackground: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "5B5A8E"), Color(hex: "3E3D6B")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(Color.black.opacity(0.5))
    }
}

// MARK: - Profile Section

private extension AccountView {
    
    var profileSection: some View {
        HStack(spacing: 10) {
            avatarCircle
            
            VStack(alignment: .leading, spacing: 2) {
                if let firstName = injected.appState[\.userData.userId] != nil ? "PATRICK" : "User",
                   let lastName = injected.appState[\.userData.userId] != nil ? "DEVRU" : "Name" {
                    Text("\(firstName) \(lastName)")
                        .font(.rubik(.extraBold, size: 20))
                        .foregroundColor(Color(hex: "11104B"))
                        .textCase(.uppercase)
                }
                
                Text("\(injected.appState[\.userData.starredEventIds].count) events saved")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
            }
            
            Spacer()
            
            Button {
                showEditProfileAlert = true
            } label: {
                Text("Edit Profile")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "4B7BE2"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "F25454"))
                .frame(width: 60, height: 60)
            
            Text(userInitials)
                .font(.rubik(.extraBold, size: 20))
                .foregroundColor(.white)
                .textCase(.uppercase)
        }
    }
    
    var userInitials: String {
        if injected.appState[\.userData.userId] != nil {
            return "PD"
        }
        return "U"
    }
}

// MARK: - Calendar & Export Section

private extension AccountView {
    
    var calendarExportSection: some View {
        VStack(spacing: 5) {
            sectionHeader("CALENDAR & EXPORT")
            
            VStack(spacing: 1) {
                eventCalendarRow
                includeSourceLinksRow
            }
        }
    }
    
    var eventCalendarRow: some View {
        Button {
            showCalendarAlert = true
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image("calendar")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(hex: "11104B"))
                            .frame(width: 13, height: 13)
                        
                        Text("Event Calendar")
                            .font(.rubik(.regular, size: 14))
                            .foregroundColor(Color(hex: "11104B"))
                    }
                    
                    if calendarConnected {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connected: Google Calendar (Personal)")
                                .font(.rubik(.regular, size: 13))
                                .foregroundColor(Color(hex: "55564F"))
                            
                            if let email = injected.appState[\.userData.email] {
                                Text(email)
                                    .font(.rubik(.regular, size: 13))
                                    .foregroundColor(Color(hex: "55564F"))
                            }
                        }
                        .padding(.leading, 23)
                    }
                }
                
                Spacer()
                
                if calendarConnected {
                    HStack(spacing: 6) {
                        Text("Disconnect")
                            .font(.rubik(.regular, size: 14))
                            .foregroundColor(Color(hex: "F25454"))
                        
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "F25454"))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 2)
                    .background(Color(hex: "F25454").opacity(0.1))
                    .clipShape(Capsule())
                } else {
                    HStack(spacing: 6) {
                        Text("Not Connected")
                            .font(.rubik(.regular, size: 14))
                            .foregroundColor(Color(hex: "F25454"))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(Color(hex: "F25454"))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
        }
        .buttonStyle(.plain)
    }
    
    var includeSourceLinksRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image("links")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(hex: "11104B"))
                        .frame(width: 13, height: 13)
                    
                    Text("Include Source Links")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                }
                
                Text("Add original links to calendar events")
                    .font(.rubik(.regular, size: 13))
                    .foregroundColor(Color(hex: "55564F"))
                    .padding(.leading, 23)
                    .padding(.top, 0)
            }
            
            Spacer()
            
            CustomToggle(isOn: $includeSourceLinks) {
                showSourceLinksAlert = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
}

// MARK: - Notifications Section

private extension AccountView {
    
    var notificationsSection: some View {
        VStack(spacing: 5) {
            sectionHeader("NOTIFICATIONS")
            
            VStack(spacing: 1) {
                eventRemindersRow
                registrationDeadlinesRow
                systemNotificationsRow
            }
        }
    }
    
    var eventRemindersRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image("reminders")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(hex: "11104B"))
                        .frame(width: 13, height: 13)
                    
                    Text("Event Reminders")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                }
                
                Spacer()
                
                CustomToggle(isOn: $eventRemindersEnabled) {
                    showNotificationAlert = true
                }
            }
            
            if eventRemindersExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Get notified before events you're attending")
                        .font(.rubik(.regular, size: 13))
                        .foregroundColor(Color(hex: "55564F"))
                        .padding(.leading, 23)
                        .padding(.bottom, 10)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("When you mark an event as \"Going\":")
                            .font(.rubik(.regular, size: 13))
                            .foregroundColor(Color(hex: "11104B"))
                            .padding(.leading, 23)
                        
                        VStack(spacing: 10) {
                            checkboxRow(isChecked: $reminderWeekBefore, title: "1 week before")
                            checkboxRow(isChecked: $reminderDayBefore, title: "1 day before")
                            checkboxRow(isChecked: $reminder3Hours, title: "3 hours before")
                        }
                        .padding(.leading, 23)
                    }
                    .padding(.bottom, 10)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("When you mark an event as \"Interested\":")
                            .font(.rubik(.regular, size: 13))
                            .foregroundColor(Color(hex: "11104B"))
                            .padding(.leading, 23)
                        
                        checkboxRow(isChecked: $reminderInterestedDayBefore, title: "1 day before")
                            .padding(.leading, 23)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
    
    var registrationDeadlinesRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image("registration-deadlines")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(hex: "11104B"))
                        .frame(width: 13, height: 13)
                    
                    Text("Registration Deadlines")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                }
                
                Text("Alerts when registration closes soon (3 days or less) - For events marked \"Going\" or \"Interested\"")
                    .font(.rubik(.regular, size: 13))
                    .foregroundColor(Color(hex: "55564F"))
                    .padding(.leading, 23)
                    .padding(.trailing, 40)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            CustomToggle(isOn: $registrationDeadlinesEnabled) {
                showRegistrationAlert = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
    
    var systemNotificationsRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image("system-notifications")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(hex: "11104B"))
                        .frame(width: 13, height: 13)
                    
                    Text("System Notifications")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                }
                
                Text("App updates and important announcements")
                    .font(.rubik(.regular, size: 13))
                    .foregroundColor(Color(hex: "55564F"))
                    .padding(.leading, 23)
            }
            
            Spacer()
            
            CustomToggle(isOn: $systemNotificationsEnabled) {
                showSystemNotificationsAlert = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
    
    func checkboxRow(isChecked: Binding<Bool>, title: String) -> some View {
        Button {
            isChecked.wrappedValue.toggle()
        } label: {
            HStack(spacing: 10) {
                CustomCheckbox(isChecked: isChecked.wrappedValue)
                
                Text(title)
                    .font(.rubik(.regular, size: 13))
                    .foregroundColor(Color(hex: "55564F"))
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data & Privacy Section

private extension AccountView {
    
    var dataPrivacySection: some View {
        VStack(spacing: 5) {
            sectionHeader("DATA & PRIVACY")
            
            analyticsRow
        }
    }
    
    var analyticsRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image("analytics")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "11104B"))
                        .frame(width: 13)
                    
                    Text("Analytics")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                }
                
                Text("Help us improve the app")
                    .font(.rubik(.regular, size: 13))
                    .foregroundColor(Color(hex: "55564F"))
                    .padding(.leading, 23)
            }
            
            Spacer()
            
            CustomToggle(isOn: $analyticsEnabled) {
                showAnalyticsAlert = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
}

// MARK: - Support & Info Section

private extension AccountView {
    
    var supportInfoSection: some View {
        VStack(spacing: 5) {
            sectionHeader("SUPPORT & INFO")
            
            VStack(spacing: 1) {
                supportRow(icon: "send-feedback", title: "Send Feedback") {
                    showFeedbackAlert = true
                }
                supportRow(icon: "rate-the-app", title: "Rate the App") {
                    showRateAppAlert = true
                }
                supportRow(icon: "privacy-policy", title: "Privacy Policy") {
                    showPrivacyPolicyAlert = true
                }
            }
        }
    }
    
    func supportRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 10) {
                Image(icon)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 13)
                
                Text(title)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 5)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sign Out Section

private extension AccountView {
    
    var signOutSection: some View {
        VStack(spacing: 0) {
            Button {
                signOut()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "F25454"))
                        .frame(width: 13)
                    
                    Text("Sign Out")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "F25454"))
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.white)
            }
            .buttonStyle(.plain)
            .disabled(isSigningOut)
            .opacity(isSigningOut ? 0.5 : 1)
        }
        .padding(.top, 10)
    }
}

// MARK: - Footer

private extension AccountView {
    
    var footer: some View {
        Text("Version 1.0.0")
            .font(.rubik(.regular, size: 12))
            .foregroundColor(Color(hex: "55564F"))
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 80)
    }
}

// MARK: - Helper Views

private extension AccountView {
    
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.rubik(.medium, size: 11))
            .foregroundColor(Color(hex: "55564F"))
            .textCase(.uppercase)
            .kerning(0.44)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 15)
            .padding(.bottom, 0)
    }
}

// MARK: - Side Effects

private extension AccountView {
    
    func signOut() {
        isSigningOut = true
        Task {
            do {
                try await injected.interactors.auth.signOut()
            } catch {
                print("AccountView - Error signing out: \(error)")
            }
            await MainActor.run {
                isSigningOut = false
            }
        }
    }
}

// MARK: - Custom Components

struct CustomToggle: View {
    @Binding var isOn: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button {
            onToggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isOn ? Color(hex: "4B7BE2") : Color(hex: "EFEEE7"))
                    .frame(width: 36, height: 20)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .padding(2)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CustomCheckbox: View {
    let isChecked: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(isChecked ? Color(hex: "4B7BE2") : Color(hex: "EFEEE7"))
                .frame(width: 20, height: 20)
            
            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    AccountView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
