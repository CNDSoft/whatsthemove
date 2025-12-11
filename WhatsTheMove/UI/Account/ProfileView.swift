//
//  ProfileView.swift
//  WhatsTheMove
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
            }
        }
        .navigationBarHidden(true)
        .alert("Close Account", isPresented: $showCloseAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Close Account", role: .destructive) {
            }
        } message: {
            Text("Are you sure you want to close your account? This action cannot be undone.")
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
            infoRow(title: "First Name", value: injected.appState[\.userData.firstName] ?? "")
            infoRow(title: "Last Name", value: injected.appState[\.userData.lastName] ?? "")
            infoRow(title: "Email", value: injected.appState[\.userData.email] ?? "")
            infoRow(title: "Phone Number", value: injected.appState[\.userData.phoneNumber] ?? "Add your phone number", isPlaceholder: injected.appState[\.userData.phoneNumber] == nil)
        }
        .background(Color(hex: "F4F4F4"))
    }
    
    func infoRow(title: String, value: String, isPlaceholder: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.rubik(.medium, size: 15))
                .foregroundColor(Color(hex: "11104B"))
            
            Text(value)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
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
}

// MARK: - Previews

#Preview {
    ProfileView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
