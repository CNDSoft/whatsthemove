//
//  OnboardingPage7.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingPage7: View {
    
    var onConnectGoogle: (() -> Void)?
    var onConnectApple: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            titleSection
            
            descriptionSection
            
            calendarButtons
            
            calendarGrid
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Title Section

private extension OnboardingPage7 {
    
    var titleSection: some View {
        Text("Connect Your\nCalendar")
            .font(.rubik(.bold, size: 32))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .tracking(-0.64)
    }
}

// MARK: - Description Section

private extension OnboardingPage7 {
    
    var descriptionSection: some View {
        VStack(spacing: 0) {
            Text("Export saved events to your")
            Text("calendar with one tap")
        }
        .font(.rubik(.regular, size: 16))
        .foregroundColor(Color(hex: "11104B"))
        .multilineTextAlignment(.center)
    }
}

// MARK: - Calendar Buttons

private extension OnboardingPage7 {
    
    var calendarButtons: some View {
        VStack(spacing: 15) {
            CalendarConnectButton(
                iconName: "google",
                title: "Connect Google Calendar",
                action: { onConnectGoogle?() }
            )
            
            CalendarConnectButton(
                iconName: "apple",
                title: "Connect Apple Calendar",
                action: { onConnectApple?() }
            )
        }
    }
}

// MARK: - Calendar Grid

private extension OnboardingPage7 {
    
    var calendarGrid: some View {
        Image("onboarding7")
            .resizable()
            .scaledToFit()
            .padding(.top, 20)
    }
}

// MARK: - Previews

#Preview("Page 7") {
    OnboardingPage7()
        .background(Color(hex: "F8F7F1"))
}
