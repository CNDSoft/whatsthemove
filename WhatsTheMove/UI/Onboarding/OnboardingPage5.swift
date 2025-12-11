//
//  OnboardingPage5.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingPage5: View {
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            titleSection
            
            illustrationSection
            
            descriptionSection
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Title Section

private extension OnboardingPage5 {
    
    var titleSection: some View {
        Text("Find events when you need them")
            .font(.rubik(.bold, size: 32))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .tracking(-0.64)
            .lineSpacing(2)
    }
}

// MARK: - Illustration Section

private extension OnboardingPage5 {
    
    var illustrationSection: some View {
        Image("onboarding5")
            .resizable()
            .frame(width: 295, height: 240)
            .scaledToFit()
    }
}

// MARK: - Description Section

private extension OnboardingPage5 {
    
    var descriptionSection: some View {
        Text("No more scrolling through screenshots. Filter by when you're free and instantly see your options of things to do.")
            .font(.rubik(.regular, size: 14))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .lineSpacing(3)
    }
}

// MARK: - Previews

#Preview("Page 5") {
    OnboardingPage5()
        .background(Color(hex: "F8F7F1"))
}
