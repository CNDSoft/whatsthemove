//
//  RegisterView.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct RegisterView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var selectedAgeRange: AgeRange = .eighteen
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showAgePicker: Bool = false
    
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
        }
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
    }
}

// MARK: - Age Range

extension RegisterView {
    
    enum AgeRange: String, CaseIterable {
        case eighteen = "18-24"
        case twentyFive = "25-34"
        case thirtyFive = "35-44"
        case fortyFive = "45-54"
        case fiftyFive = "55+"
    }
}

// MARK: - Header Section

private extension RegisterView {
    
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

private extension RegisterView {
    
    var formSection: some View {
        VStack(spacing: 1) {
            RegisterFormField(
                label: "First Name",
                placeholder: "Enter your first name",
                text: $firstName
            )
            
            RegisterFormField(
                label: "Last Name",
                placeholder: "Enter your last name",
                text: $lastName
            )
            
            RegisterFormField(
                label: "Email",
                placeholder: "Enter your email",
                text: $email,
                keyboardType: .emailAddress
            )
            
            agePickerField
            
            RegisterFormField(
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
    
    var agePickerField: some View {
        Button(action: {
            showAgePicker = true
        }) {
            HStack {
                Text("Age")
                    .font(.rubik(.medium, size: 15))
                    .foregroundColor(Color(hex: "11104B"))
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(selectedAgeRange.rawValue)
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "55564F"))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "55564F"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .buttonStyle(.plain)
        .confirmationDialog("Select Age Range", isPresented: $showAgePicker, titleVisibility: .visible) {
            ForEach(AgeRange.allCases, id: \.self) { range in
                Button(range.rawValue) {
                    selectedAgeRange = range
                }
            }
        }
    }
}

// MARK: - Menu Section

private extension RegisterView {
    
    var menuSection: some View {
        VStack(spacing: 15) {
            createAccountButton
            signInLink
        }
        .padding(20)
    }
    
    var createAccountButton: some View {
        Button(action: handleRegister) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "F8F7F1")))
                } else {
                    Text("Create an account")
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
    
    var signInLink: some View {
        HStack(spacing: 0) {
            Text("Already have an account? ")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
            
            Button(action: {
                dismiss()
            }) {
                Text("Sign in")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                    .underline()
            }
        }
    }
}

// MARK: - Side Effects

private extension RegisterView {
    
    func handleRegister() {
        guard !firstName.isEmpty else {
            errorMessage = "Please enter your first name"
            return
        }
        
        guard !lastName.isEmpty else {
            errorMessage = "Please enter your last name"
            return
        }
        
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }
        
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                try await injected.interactors.auth.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    ageRange: selectedAgeRange.rawValue
                )
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("RegisterView - Error: \(error)")
            }
        }
    }
}

// MARK: - Register Form Field

private struct RegisterFormField: View {
    
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    @State private var isPasswordVisible: Bool = false
    
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
            
            HStack(spacing: 8) {
                if isSecure && !isPasswordVisible {
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
                
                if isSecure {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "55564F"))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }
}

// MARK: - Previews

#Preview("Register") {
    RegisterView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
