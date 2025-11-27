//
//  OnboardingView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var currentPage: Int = 0
    var onComplete: () -> Void
    var onRequestCameraAccess: (() -> Void)?
    var onRequestNotifications: (() -> Void)?
    var onConnectGoogleCalendar: (() -> Void)?
    var onConnectAppleCalendar: (() -> Void)?
    
    private let totalPages = 7
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage1()
                        .tag(0)
                    
                    OnboardingPage2()
                        .tag(1)
                    
                    OnboardingPage3()
                        .tag(2)
                    
                    OnboardingPage4()
                        .tag(3)
                    
                    OnboardingPage5()
                        .tag(4)
                    
                    OnboardingPage6(
                        onConnectGoogle: {
                            onConnectGoogleCalendar?()
                            goToNextPage()
                        },
                        onConnectApple: {
                            onConnectAppleCalendar?()
                            goToNextPage()
                        }
                    )
                    .tag(5)
                    
                    OnboardingPage7()
                        .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                if currentPage < totalPages - 1 {
                    bottomSection
                } else {
                    finalBottomSection
                }
            }
        }
    }
}

// MARK: - Styling

private extension OnboardingView {
    
    var backgroundColor: Color {
        currentPage == 6 ? Color(hex: "11104B") : Color(hex: "F8F7F1")
    }
}

// MARK: - Bottom Section

private extension OnboardingView {
    
    var bottomSection: some View {
        VStack(spacing: 10) {
            pageIndicator
                .padding(.vertical, 10)
            
            if shouldShowPrimaryButton {
                primaryButton
            }
            
            if shouldShowSkipButton {
                skipButton
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
    }
    
    var finalBottomSection: some View {
        VStack(spacing: 10) {
            getStartedButton
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 50)
    }
    
    var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages - 1, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color(hex: "11104B") : Color(hex: "11104B").opacity(0.2))
                    .frame(width: 7, height: 7)
            }
        }
    }
    
    var primaryButton: some View {
        Button(action: {
            handlePrimaryAction()
        }) {
            Text(primaryButtonTitle)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "F8F7F1"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(Color(hex: "11104B"))
                )
        }
    }
    
    var skipButton: some View {
        Button(action: {
            handleSkipAction()
        }) {
            Text("Skip")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(Color(hex: "E8E8FF"))
                )
        }
    }
    
    var getStartedButton: some View {
        Button(action: {
            onComplete()
        }) {
            Text("Get Started")
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
}

// MARK: - Button Configuration

private extension OnboardingView {
    
    var primaryButtonTitle: String {
        switch currentPage {
        case 0:
            return "Yeah, this is me"
        case 1:
            return "Next"
        case 2:
            return "Allow Camera Access"
        case 3:
            return "Love it"
        case 4:
            return "Enable notifications"
        default:
            return "Next"
        }
    }
    
    var shouldShowPrimaryButton: Bool {
        currentPage != 5
    }
    
    var shouldShowSkipButton: Bool {
        switch currentPage {
        case 1, 2, 4, 5:
            return true
        default:
            return false
        }
    }
    
    func handlePrimaryAction() {
        switch currentPage {
        case 2:
            onRequestCameraAccess?()
            goToNextPage()
        case 4:
            onRequestNotifications?()
            goToNextPage()
        default:
            goToNextPage()
        }
    }
    
    func handleSkipAction() {
        goToNextPage()
    }
    
    func goToNextPage() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        }
    }
}

// MARK: - Previews

#Preview("Onboarding") {
    OnboardingView(onComplete: {})
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
