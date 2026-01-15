//
//  OnboardingView.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    
    @Environment(\.injected) private var injected: DIContainer
    @State private var currentPage: Int = 0
    @State private var direction: TransitionDirection = .forward
    @State private var showShareSheet: Bool = false
    var onComplete: () -> Void
    var onRequestCameraAccess: (() -> Void)?
    var onRequestNotifications: (() -> Void)?
    var onConnectGoogleCalendar: (() -> Void)?
    var onConnectAppleCalendar: (() -> Void)?
    
    private let totalPages = 8
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: currentPage)
            
            VStack(spacing: 0) {
                pageContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if currentPage < totalPages - 1 {
                    bottomSection
                } else {
                    finalBottomSection
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["https://www.example.com"])
        }
    }
    
    @ViewBuilder
    private var pageContent: some View {
        Group {
            switch currentPage {
            case 0:
                OnboardingPage1()
                    .transition(pageTransition)
            case 1:
                OnboardingPage2()
                    .transition(pageTransition)
            case 2:
                OnboardingPage3()
                    .transition(pageTransition)
            case 3:
                OnboardingPage4()
                    .transition(pageTransition)
            case 4:
                OnboardingPage5()
                    .transition(pageTransition)
            case 5:
                OnboardingPage6()
                    .transition(pageTransition)
            case 6:
                OnboardingPage7(
                    onConnectGoogle: {
                        onConnectGoogleCalendar?()
                        goToNextPage()
                    },
                    onConnectApple: {
                        onConnectAppleCalendar?()
                        goToNextPage()
                    }
                )
                .transition(pageTransition)
            case 7:
                OnboardingPage8()
                    .transition(pageTransition)
            default:
                EmptyView()
            }
        }
        .id(currentPage)
    }
    
    private var pageTransition: AnyTransition {
        if direction == .forward {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        } else {
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
}

// MARK: - Transition Direction

private extension OnboardingView {
    
    enum TransitionDirection {
        case forward
        case backward
    }
}

// MARK: - Styling

private extension OnboardingView {
    
    var backgroundColor: Color {
        currentPage == 7 ? Color(hex: "11104B") : Color(hex: "F8F7F1")
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
            Text(skipButtonTitle)
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
            Text("Save my first event")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(Color(hex: "E7FF63"))
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
            return "Next"
        case 3:
            return "Open the Share Menu"
        case 4:
            return "Love it"
        case 5:
            return "Enable notifications"
        default:
            return "Next"
        }
    }
    
    var skipButtonTitle: String {
        currentPage == 6 ? "Next" : "Skip"
    }
    
    var shouldShowPrimaryButton: Bool {
        currentPage != 6
    }
    
    var shouldShowSkipButton: Bool {
        switch currentPage {
        case 3, 5, 6:
            return true
        default:
            return false
        }
    }
    
    func handlePrimaryAction() {
        switch currentPage {
        case 3:
            showShareSheet = true
        case 5:
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
            direction = .forward
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage += 1
            }
        }
    }
    
    func goToPreviousPage() {
        if currentPage > 0 {
            direction = .backward
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage -= 1
            }
        }
    }
}

// MARK: - Previews

#Preview("Onboarding") {
    OnboardingView(onComplete: {})
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}
