//
//  OnboardingPage4.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/10/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingPage4: View {
    
    var body: some View {
        VStack(spacing: 0) {
            contentSection
            
            Spacer()
            
            mockDeviceSection
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Content Section

private extension OnboardingPage4 {
    
    var contentSection: some View {
        VStack(spacing: 20) {
            Spacer()
            
            titleSection
            
            descriptionSection
            
            stepsSection
        }
    }
}

// MARK: - Title Section

private extension OnboardingPage4 {
    
    var titleSection: some View {
        Text("Set up link sharing")
            .font(.rubik(.bold, size: 32))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .tracking(-0.64)
            .lineSpacing(2)
    }
}

// MARK: - Description Section

private extension OnboardingPage4 {
    
    var descriptionSection: some View {
        Text("Add the wtm extension to your Favorites to save content from other apps.")
            .font(.rubik(.regular, size: 14))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .lineSpacing(6)
    }
}

// MARK: - Steps Section

private extension OnboardingPage4 {
    
    var stepsSection: some View {
        VStack(spacing: 10) {
            stepRow(number: "1", text: "Open the share menu")
            stepRow(number: "2", text: "Scroll past all your apps and tap \"More\"")
            stepRow(number: "3", text: "Tap edit, find \"wtm\", tap the + icon")
        }
    }
    
    func stepRow(number: String, text: String) -> some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color(hex: "E8E8FF"))
                )
            
            Text(text)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(6)
        }
    }
}

// MARK: - Mock Device Section

private extension OnboardingPage4 {
    
    var mockDeviceSection: some View {
        Image("onboarding4")
            .resizable()
            .scaledToFit()
            .frame(width: 295, height: 241)
    }
}

// MARK: - Previews

#Preview("Page 4") {
    OnboardingPage4()
        .background(Color(hex: "F8F7F1"))
}
