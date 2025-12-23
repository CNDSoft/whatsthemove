//
//  PrivacyPolicyView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/23/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import Combine

struct PrivacyPolicyView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.injected) private var injected: DIContainer
    @State private var privacyPolicyText: Loadable<String> = .notRequested
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                content
            }
        }
        .onAppear {
            loadPrivacyPolicy()
        }
    }
    
    @ViewBuilder private var content: some View {
        switch privacyPolicyText {
        case .notRequested:
            defaultView()
        case .isLoading:
            loadingView()
        case let .loaded(text):
            loadedView(text)
        case let .failed(error):
            failedView(error)
        }
    }
}

// MARK: - Header Section

private extension PrivacyPolicyView {
    
    var headerSection: some View {
        HStack {
            closeButton
            
            Spacer()
            
            Text("PRIVACY POLICY")
                .font(.rubik(.extraBold, size: 20))
                .foregroundColor(Color(hex: "11104B"))
                .textCase(.uppercase)
            
            Spacer()
            
            Color.clear
                .frame(width: 38, height: 38)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Circle()
                .fill(Color(hex: "F25454"))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Loading Content

private extension PrivacyPolicyView {
    
    func defaultView() -> some View {
        Color.clear
    }
    
    func loadingView() -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "11104B")))
            
            Text("Loading Privacy Policy...")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func failedView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "F25454"))
            
            Text("Failed to load Privacy Policy")
                .font(.rubik(.semiBold, size: 16))
                .foregroundColor(Color(hex: "11104B"))
            
            Text(error.localizedDescription)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                loadPrivacyPolicy()
            } label: {
                Text("Try Again")
                    .font(.rubik(.medium, size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color(hex: "4B7BE2"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}

// MARK: - Displaying Content

private extension PrivacyPolicyView {
    
    func loadedView(_ text: String) -> some View {
        ScrollView {
            Text(text)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
                .lineSpacing(6)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Side Effects

private extension PrivacyPolicyView {
    
    func loadPrivacyPolicy() {
        guard privacyPolicyText != .isLoading(last: nil, cancelBag: CancelBag()) else {
            return
        }
        
        privacyPolicyText = .isLoading(last: privacyPolicyText.value, cancelBag: CancelBag())
        
        Task {
            do {
                let text = try await injected.interactors.remoteConfig.fetchPrivacyPolicyText()
                await MainActor.run {
                    privacyPolicyText = .loaded(text)
                    print("PrivacyPolicyView - Privacy policy loaded successfully")
                }
            } catch {
                await MainActor.run {
                    privacyPolicyText = .failed(error)
                    print("PrivacyPolicyView - Error loading privacy policy: \(error)")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    PrivacyPolicyView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}

