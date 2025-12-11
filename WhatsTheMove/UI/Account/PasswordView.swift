//
//  PasswordView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/11/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct PasswordView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var isUpdating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                contentSection
                updateButton
                validationText
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Password updated successfully")
        }
    }
}

// MARK: - Header Section

private extension PasswordView {
    
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
            
            Text("PASSWORD")
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

private extension PasswordView {
    
    var contentSection: some View {
        VStack(spacing: 1) {
            LoginFormField(
                label: "Current Password",
                placeholder: "Enter current password",
                text: $currentPassword,
                isSecure: true
            )
            
            LoginFormField(
                label: "New Password*",
                placeholder: "Enter new password",
                text: $newPassword,
                isSecure: true
            )
            
            LoginFormField(
                label: "Confirm New Password*",
                placeholder: "Confirm new password",
                text: $confirmPassword,
                isSecure: true
            )
        }
        .background(Color(hex: "F4F4F4"))
    }
    
    var updateButton: some View {
        Button {
            updatePassword()
        } label: {
            Text("Update Password")
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
        .disabled(isUpdating || !isFormValid)
        .opacity(isUpdating || !isFormValid ? 0.5 : 1)
    }
    
    var validationText: some View {
        Text("*8 characters minimum")
            .font(.rubik(.regular, size: 12))
            .foregroundColor(Color(hex: "55564F"))
            .padding(.top, 5)
    }
    
    var isFormValid: Bool {
        return !currentPassword.isEmpty &&
               !newPassword.isEmpty &&
               !confirmPassword.isEmpty &&
               newPassword.count >= 8 &&
               newPassword == confirmPassword
    }
}

// MARK: - Side Effects

private extension PasswordView {
    
    func updatePassword() {
        guard isFormValid else { return }
        
        isUpdating = true
        
        Task {
            do {
                try await injected.interactors.auth.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                
                await MainActor.run {
                    isUpdating = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
                print("PasswordView - Error updating password: \(error)")
            }
        }
    }
}

// MARK: - Previews

#Preview {
    PasswordView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
