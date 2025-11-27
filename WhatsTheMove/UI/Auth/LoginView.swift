//
//  LoginView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showRegister: Bool = false
    @State private var showForgotPasswordAlert: Bool = false
    @State private var forgotPasswordEmail: String = ""
    @State private var showPasswordResetSuccess: Bool = false
    @State private var isResettingPassword: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: "F8F7F1")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection
                    
                    formSection
                    
                    menuSection
                    
                    Spacer()
                }
            }
        }.ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showRegister) {
            RegisterView()
        }
        .alert("Reset Password", isPresented: $showForgotPasswordAlert) {
            TextField("Email", text: $forgotPasswordEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            Button("Cancel", role: .cancel) {
                forgotPasswordEmail = ""
            }
            Button("Send Reset Link") {
                handleResetPassword()
            }
            .disabled(forgotPasswordEmail.isEmpty)
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
        .alert("Password Reset Email Sent", isPresented: $showPasswordResetSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Check your email for instructions to reset your password.")
        }
    }
}

// MARK: - Header Section

private extension LoginView {
    
    var headerSection: some View {
        ZStack {
            Color(hex: "11104B")
            
            decorativeBackground
            
            VStack(spacing: 0) {
                ZStack {
                    Image("wtm-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 72)
                    
                    whatsTheMoveBadge
                        .offset(x: 80, y: 22)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 15)
            .padding(.horizontal, 20)
            .background(Image("header-background").resizable().frame(height: 150))
            
        }
        .frame(height: 150)
    }
    
    var decorativeBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -50)
                
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    .frame(width: 400, height: 400)
                    .offset(x: 150, y: 100)
                
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    .frame(width: 250, height: 250)
                    .offset(x: 200, y: -80)
            }
        }
        .clipped()
    }
    
    var whatsTheMoveBadge: some View {
        Text("What's The Move")
            .font(.rubik(.medium, size: 15))
            .foregroundColor(Color(hex: "11104B"))
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color(hex: "E7FF63"))
            )
            .rotationEffect(.degrees(-2))
    }
}

// MARK: - Form Section

private extension LoginView {
    
    var formSection: some View {
        VStack(spacing: 1) {
            LoginFormField(
                label: "Email",
                placeholder: "Enter your email",
                text: $email,
                keyboardType: .emailAddress
            )
            
            LoginFormField(
                label: "Password",
                placeholder: "Enter your password",
                text: $password,
                isSecure: true
            )
            
            if let errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color(hex: "FF6B6B"))
                    Text(errorMessage)
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "FF6B6B"))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
            }
        }
        .background(Color(hex: "F4F4F4"))
    }
}

// MARK: - Menu Section

private extension LoginView {
    
    var menuSection: some View {
        VStack(spacing: 10) {
            signInButton
            
            VStack(spacing: 10) {
                signUpLink
                forgotPasswordLink
            }
        }
        .padding(20)
    }
    
    var signInButton: some View {
        Button(action: handleSignIn) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "F8F7F1")))
                } else {
                    Text("Sign in")
                        .font(.rubik(.regular, size: 14))
                }
            }
            .foregroundColor(Color(hex: "F8F7F1"))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(Color(hex: "11104B"))
            )
        }
        .disabled(isLoading)
    }
    
    var signUpLink: some View {
        HStack(spacing: 0) {
            Text("Don't have an account?")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
            
            Button(action: handleNavigateToSignUp) {
                Text(" Sign up")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                    .underline()
            }
        }
    }
    
    var forgotPasswordLink: some View {
        Button(action: handleForgotPassword) {
            Text("Forgot password?")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
                .underline()
        }
    }
}

// MARK: - Side Effects

private extension LoginView {
    
    func handleSignIn() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                try await injected.interactors.auth.signIn(email: email, password: password)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("LoginView - Sign in error: \(error)")
            }
        }
    }
    
    func handleForgotPassword() {
        print("LoginView - Forgot password tapped")
        forgotPasswordEmail = email
        showForgotPasswordAlert = true
    }
    
    func handleResetPassword() {
        guard !forgotPasswordEmail.isEmpty else { return }
        
        isResettingPassword = true
        errorMessage = nil
        
        Task {
            do {
                try await injected.interactors.auth.resetPassword(email: forgotPasswordEmail)
                isResettingPassword = false
                forgotPasswordEmail = ""
                showPasswordResetSuccess = true
            } catch {
                isResettingPassword = false
                errorMessage = error.localizedDescription
                print("LoginView - Reset password error: \(error)")
            }
        }
    }
    
    func handleNavigateToSignUp() {
        showRegister = true
    }
}

// MARK: - Login Form Field

private struct LoginFormField: View {
    
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    private var placeholderText: Text {
        Text(placeholder)
            .font(.rubik(.regular, size: 14))
            .foregroundColor(Color(hex: "55564F"))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.rubik(.medium, size: 15))
                .foregroundColor(Color(hex: "11104B"))
                .lineSpacing(20 - 15)
            
            if isSecure {
                SecureField("", text: $text, prompt: placeholderText)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                    .lineSpacing(20 - 14)
            } else {
                TextField("", text: $text, prompt: placeholderText)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .lineSpacing(20 - 14)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }
}

// MARK: - Previews

#Preview("Login") {
    LoginView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
