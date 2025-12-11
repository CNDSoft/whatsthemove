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
        .fullScreenCover(item: $showAuthForm) { formType in
            NavigationStack {
                switch formType {
                case .signIn:
                    LoginView()
                case .signUp:
                    RegisterView()
                }
            }
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
            
            Text("Save events you\n discover. Never run\n out of things to do")
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

// MARK: - Previews

#Preview("Landing") {
    AuthView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
