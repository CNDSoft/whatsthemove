//
//  ProfileView.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 12/11/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct ProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var showCloseAccountAlert: Bool = false
    @State private var deletePassword: String = ""
    @State private var isDeletingAccount: Bool = false
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var selectedTimezone: String = TimeZone.current.identifier
    @State private var showTimezonePicker: Bool = false
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                ScrollView {
                    contentSection
                }
                .scrollIndicators(.hidden)
                
                if shouldShowSaveButton {
                    saveButton
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            firstName = injected.appState[\.userData.firstName] ?? ""
            lastName = injected.appState[\.userData.lastName] ?? ""
            email = injected.appState[\.userData.email] ?? ""
            phoneNumber = injected.appState[\.userData.phoneNumber] ?? ""
            selectedTimezone = injected.appState[\.userData.timezone]
        }
        .overlay {
            if showCloseAccountAlert {
                closeAccountDialog
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showTimezonePicker) {
            TimezonePickerView(
                selectedTimezone: $selectedTimezone,
                onSave: { timezone in
                    updateTimezone(timezone)
                }
            )
        }
    }
}

// MARK: - Header Section

private extension ProfileView {
    
    var headerSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                headerBackground(width: geometry.size.width)
                
                VStack(alignment: .leading, spacing: 20) {
                    headerTopRow.padding(.horizontal, 20)
                }
                .padding(.top, 60)
                .frame(width: geometry.size.width, alignment: .leading)
            }
        }
        .frame(height: 118 - safeAreaInsets.top)
        .edgesIgnoringSafeArea(.top)
    }
    
    func headerBackground(width: CGFloat) -> some View {
        ZStack {
            Image("saved-events-header")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: 225)
                .clipped()
        }
        .frame(width: width, height: 118)
    }
    
    var headerTopRow: some View {
        HStack(spacing: 10) {
            backButton
            
            Text("MY PROFILE")
                .font(.rubik(.extraBold, size: 30))
                .foregroundColor(.white)
                .textCase(.uppercase)
            
            Spacer()
        }
    }
    
    var backButton: some View {
        Button {
            dismiss()
        } label: {
            Circle()
                .fill(Color(hex: "E7FF63"))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "11104B"))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Content Section

private extension ProfileView {
    
    var contentSection: some View {
        VStack(spacing: 1) {
            userInfoSection
            actionButtonsSection
        }
    }
    
    var userInfoSection: some View {
        VStack(spacing: 1) {
            LoginFormField(
                label: "First Name",
                placeholder: "Enter first name",
                text: $firstName
            )
            
            LoginFormField(
                label: "Last Name",
                placeholder: "Enter last name",
                text: $lastName
            )
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Email")
                    .font(.rubik(.medium, size: 15))
                    .foregroundColor(Color(hex: "11104B"))
                    .lineSpacing(20 - 15)
                
                Text(email)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                    .lineSpacing(20 - 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
            
            phoneNumberRow
            timezoneRow
        }
        .background(Color(hex: "F4F4F4"))
    }
    
    var phoneNumberRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Phone Number")
                .font(.rubik(.medium, size: 15))
                .foregroundColor(Color(hex: "11104B"))
                .lineSpacing(20 - 15)
            
            TextField("", text: $phoneNumber, prompt: Text("Add your phone number")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F")))
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
                .keyboardType(.phonePad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineSpacing(20 - 14)
                .onChange(of: phoneNumber) { _, newValue in
                    phoneNumber = formatPhoneNumber(newValue)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
    
    var timezoneRow: some View {
        Button {
            showTimezonePicker = true
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Timezone")
                        .font(.rubik(.medium, size: 15))
                        .foregroundColor(Color(hex: "11104B"))
                    
                    Text(formatTimezoneDisplay(selectedTimezone))
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "55564F"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
        }
        .buttonStyle(.plain)
    }
    
    func formatTimezoneDisplay(_ identifier: String) -> String {
        guard let timezone = TimeZone(identifier: identifier) else {
            return identifier
        }
        let offset = timezone.secondsFromGMT() / 3600
        let offsetString = offset >= 0 ? "+\(offset)" : "\(offset)"
        let abbreviation = timezone.abbreviation() ?? ""
        return "\(identifier.replacingOccurrences(of: "_", with: " ")) (GMT\(offsetString)) \(abbreviation)"
    }
    
    var actionButtonsSection: some View {
        VStack(spacing: 5) {
            changePasswordButton
            closeAccountButton
        }
        .padding(.top, 5)
    }
    
    var changePasswordButton: some View {
        NavigationLink {
            PasswordView()
        } label: {
            HStack(spacing: 10) {
                Image("change-password")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 13, height: 13)
                
                Text("Change Password")
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
    
    var closeAccountButton: some View {
        Button {
            showCloseAccountAlert = true
        } label: {
            HStack(spacing: 10) {
                Image("close-account")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(hex: "F25454"))
                    .frame(width: 13, height: 13)
                
                Text("Close Account")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "F25454"))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
        }
        .buttonStyle(.plain)
    }
    
    var saveButton: some View {
        Button {
            saveProfile()
        } label: {
            Text("Save Changes")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "F8F7F1"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "11104B"))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .disabled(isSaving)
        .opacity(isSaving ? 0.5 : 1)
    }
}

// MARK: - Close Account Dialog

private extension ProfileView {
    
    var closeAccountDialog: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isDeletingAccount {
                        showCloseAccountAlert = false
                        deletePassword = ""
                    }
                }
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Close Account")
                        .font(.rubik(.semiBold, size: 18))
                        .foregroundColor(Color(hex: "11104B"))
                    
                    Text("Are you sure you want to close your account? This action cannot be undone and all your data will be permanently deleted.")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "55564F"))
                        .lineSpacing(20 - 14)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your password to confirm")
                            .font(.rubik(.medium, size: 13))
                            .foregroundColor(Color(hex: "11104B"))
                        
                        SecureField("Password", text: $deletePassword)
                            .font(.rubik(.regular, size: 14))
                            .foregroundColor(Color(hex: "11104B"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(hex: "F4F4F4"))
                            .cornerRadius(8)
                            .disabled(isDeletingAccount)
                    }
                }
                .padding(20)
                
                HStack(spacing: 12) {
                    Button {
                        if !isDeletingAccount {
                            showCloseAccountAlert = false
                            deletePassword = ""
                        }
                    } label: {
                        Text("Cancel")
                            .font(.rubik(.medium, size: 14))
                            .foregroundColor(Color(hex: "11104B"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "F4F4F4"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeletingAccount)
                    
                    Button {
                        if !isDeletingAccount && !deletePassword.isEmpty {
                            Task { await performDeleteAccount() }
                        }
                    } label: {
                        if isDeletingAccount {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        } else {
                            Text("Delete Account")
                                .font(.rubik(.medium, size: 14))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                    .background(deletePassword.isEmpty ? Color(hex: "F25454").opacity(0.5) : Color(hex: "F25454"))
                    .cornerRadius(8)
                    .buttonStyle(.plain)
                    .disabled(isDeletingAccount || deletePassword.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Account Deletion

private extension ProfileView {
    
    func performDeleteAccount() async {
        print("ProfileView - Starting account deletion")
        
        await MainActor.run {
            isDeletingAccount = true
        }
        
        do {
            try await injected.interactors.auth.deleteAccount(currentPassword: deletePassword)
            
            await MainActor.run {
                print("ProfileView - Account deletion completed, dismissing view")
                isDeletingAccount = false
                showCloseAccountAlert = false
                deletePassword = ""
                dismiss()
            }
        } catch {
            await MainActor.run {
                isDeletingAccount = false
                showCloseAccountAlert = false
                deletePassword = ""
                errorMessage = error.localizedDescription
                showError = true
                print("ProfileView - Error deleting account: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Validation & Helpers

private extension ProfileView {
    
    var hasChanges: Bool {
        let currentFirstName = injected.appState[\.userData.firstName] ?? ""
        let currentLastName = injected.appState[\.userData.lastName] ?? ""
        let currentPhone = injected.appState[\.userData.phoneNumber] ?? ""
        
        return firstName != currentFirstName ||
               lastName != currentLastName ||
               phoneNumber != currentPhone
    }
    
    var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        (phoneNumber.isEmpty || isValidPhoneNumber(phoneNumber))
    }
    
    var shouldShowSaveButton: Bool {
        hasChanges && isFormValid
    }
    
    func isValidPhoneNumber(_ phone: String) -> Bool {
        let cleaned = phone.filter { $0.isNumber }
        return cleaned.count >= 10
    }
    
    func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        
        if digits.count > 15 {
            return String(digits.prefix(15))
        }
        
        return digits
    }
    
    func saveProfile() {
        print("ProfileView - Saving profile")
        
        guard !isSaving else { return }
        guard isFormValid else { return }
        
        Task { await updateProfile() }
    }
    
    func updateProfile() async {
        await MainActor.run {
            isSaving = true
        }
        
        do {
            try await injected.interactors.users.updateUserProfile(
                firstName: firstName,
                lastName: lastName,
                email: email,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
            )
            
            await MainActor.run {
                isSaving = false
                print("ProfileView - Profile updated successfully")
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
                showError = true
                print("ProfileView - Error updating profile: \(error.localizedDescription)")
            }
        }
    }
    
    func updateTimezone(_ timezone: String) {
        print("ProfileView - Updating timezone to: \(timezone)")
        
        Task {
            do {
                try await injected.interactors.users.updateTimezone(timezone)
                await MainActor.run {
                    selectedTimezone = timezone
                    print("ProfileView - Timezone updated successfully")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    print("ProfileView - Error updating timezone: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ProfileView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
