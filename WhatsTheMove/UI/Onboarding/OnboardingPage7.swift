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
                .frame(height: 100)
            
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
        .font(.rubik(.regular, size: 14))
        .foregroundColor(Color(hex: "11104B"))
        .multilineTextAlignment(.center)
    }
}

// MARK: - Calendar Buttons

private extension OnboardingPage7 {
    
    var calendarButtons: some View {
        VStack(spacing: 15) {
            calendarButton(
                iconName: "google",
                title: "Connect Google Calendar",
                action: { onConnectGoogle?() }
            )
            
            calendarButton(
                iconName: "apple",
                title: "Connect Apple Calendar",
                action: { onConnectApple?() }
            )
        }
    }
    
    func calendarButton(
        iconName: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .frame(width: 30)
                
                Text(title)
                    .font(.rubik(.regular, size: 15))
                    .foregroundColor(Color(hex: "11104B"))
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.trailing, 30)
            .padding(.leading, 40)
            .padding(.vertical, 15)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color(hex: "EFEEE7"), radius: 0, x: 0, y: 3)
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
