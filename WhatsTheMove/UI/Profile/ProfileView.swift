//
//  ProfileView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct ProfileView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var isSigningOut: Bool = false
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            content
        }
    }
}

// MARK: - Content

private extension ProfileView {
    
    var content: some View {
        VStack(spacing: 0) {
            header
            
            Spacer()
            
            profileInfo
            
            Spacer()
            
            signOutButton
                .padding(.bottom, 100)
        }
        .padding(.horizontal, 20)
    }
    
    var header: some View {
        Text("Profile")
            .font(.rubik(.bold, size: 24))
            .foregroundColor(Color(hex: "11104B"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
    }
    
    var profileInfo: some View {
        VStack(spacing: 16) {
            profileAvatar
            
            if let email = injected.appState.value.userData.email {
                Text(email)
                    .font(.rubik(.medium, size: 16))
                    .foregroundColor(Color(hex: "11104B"))
            }
        }
    }
    
    var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "11104B").opacity(0.1))
                .frame(width: 80, height: 80)
            
            Image(systemName: "person.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "11104B"))
        }
    }
    
    var signOutButton: some View {
        Button {
            signOut()
        } label: {
            HStack(spacing: 10) {
                if isSigningOut {
                    ProgressView()
                        .tint(Color(hex: "F8F7F1"))
                } else {
                    Text("Sign Out")
                        .font(.rubik(.semiBold, size: 16))
                }
            }
            .foregroundColor(Color(hex: "F8F7F1"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(hex: "11104B"))
            .clipShape(Capsule())
        }
        .disabled(isSigningOut)
    }
}

// MARK: - Side Effects

private extension ProfileView {
    
    func signOut() {
        isSigningOut = true
        Task {
            do {
                try await injected.interactors.auth.signOut()
            } catch {
                print("ProfileView - Error signing out: \(error)")
            }
            await MainActor.run {
                isSigningOut = false
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ProfileView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}

