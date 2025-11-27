//
//  AuthView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct AuthView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var showAuthForm: AuthFormType?
    
    var body: some View {
        ZStack {
            Color(hex: "11104B")
                .ignoresSafeArea()
            
            backgroundPattern
            
            VStack(spacing: 0) {
                Spacer()
                
                logoSection
                
                Spacer()
                
                actionButtons
            }
        }
        .sheet(item: $showAuthForm) { formType in
            AuthFormView(formType: formType)
        }
    }
}

// MARK: - Background Pattern

private extension AuthView {
    
    var backgroundPattern: some View {
        Image("auth-background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

// MARK: - Logo Section

private extension AuthView {
    
    var logoSection: some View {
        VStack(spacing: 20) {
            Image("wtm-logo")
                .resizable()
                .scaledToFit()
                .frame(height: 92)
            
            Text("Save events you discover. Never run out of things to do")
                .font(.rubik(.bold, size: 28))
                .foregroundColor(Color(hex: "F8F7F1"))
                .multilineTextAlignment(.center)
                .tracking(-0.56)
                .lineSpacing(4)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Action Buttons

private extension AuthView {
    
    var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: {
                showAuthForm = .signUp
            }) {
                Text("Register")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Color(hex: "4B7BE2"))
                    )
            }
            
            Button(action: {
                showAuthForm = .signIn
            }) {
                Text("Sign In")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Color(hex: "F8F7F1"))
                    )
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 60)
    }
}

// MARK: - Auth Form Type

enum AuthFormType: Identifiable {
    case signIn
    case signUp
    
    var id: String {
        switch self {
        case .signIn: return "signIn"
        case .signUp: return "signUp"
        }
    }
}

// MARK: - Auth Form View

private struct AuthFormView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.dismiss) private var dismiss
    let formType: AuthFormType
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color(hex: "11104B")
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                headerSection
                
                Spacer()
                
                formSection
                
                actionButton
                
                Spacer()
            }
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Header Section

private extension AuthFormView {
    
    var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "F8F7F1"))
                }
                
                Spacer()
            }
            .padding(.top, 20)
            
            Image("wtm-logo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
            
            Text(formType == .signIn ? "Welcome Back" : "Create Account")
                .font(.rubik(.semiBold, size: 24))
                .foregroundColor(Color(hex: "F8F7F1"))
        }
    }
}

// MARK: - Form Section

private extension AuthFormView {
    
    var formSection: some View {
        VStack(spacing: 16) {
            if formType == .signUp {
                AuthTextField(
                    placeholder: "Name",
                    text: $name,
                    icon: "person.fill"
                )
            }
            
            AuthTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope.fill",
                keyboardType: .emailAddress
            )
            
            AuthTextField(
                placeholder: "Password",
                text: $password,
                icon: "lock.fill",
                isSecure: true
            )
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Action Button

private extension AuthFormView {
    
    var actionButton: some View {
        Button(action: handleAuth) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "11104B")))
                } else {
                    Text(formType == .signIn ? "Sign In" : "Sign Up")
                        .font(.rubik(.semiBold, size: 16))
                }
            }
            .foregroundColor(Color(hex: "11104B"))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(Color(hex: "E7FF63"))
            )
        }
        .disabled(isLoading || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
    }
    
    var isFormValid: Bool {
        if formType == .signIn {
            return !email.isEmpty && !password.isEmpty
        } else {
            return !email.isEmpty && !password.isEmpty && !name.isEmpty
        }
    }
}

// MARK: - Side Effects

private extension AuthFormView {
    
    func handleAuth() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                if formType == .signIn {
                    try await injected.interactors.auth.signIn(email: email, password: password)
                } else {
                    try await injected.interactors.auth.signUp(email: email, password: password, name: name)
                }
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("AuthFormView - Error: \(error)")
            }
        }
    }
}

// MARK: - Auth Text Field

struct AuthTextField: View {
    
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "11104B").opacity(0.6))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.rubik(.regular, size: 15))
            } else {
                TextField(placeholder, text: $text)
                    .font(.rubik(.regular, size: 15))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F8F7F1"))
        )
        .foregroundColor(Color(hex: "11104B"))
    }
}

// MARK: - Previews

#Preview("Landing") {
    AuthView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
