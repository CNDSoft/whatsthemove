//
//  OnboardingPage3.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingPage3: View {
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
                .frame(height: 100)
            
            titleSection
            
            illustrationSection
            
            descriptionSection
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Title Section

private extension OnboardingPage3 {
    
    var titleSection: some View {
        Text("Save events as you discover them")
            .font(.rubik(.bold, size: 32))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .tracking(-0.64)
            .lineSpacing(2)
    }
}

// MARK: - Illustration Section

private extension OnboardingPage3 {
    
    var illustrationSection: some View {
        Image("onboarding3")
            .resizable()
            .scaledToFit()
            .frame(width: 320, height: 165)
    }
}

// MARK: - Description Section

private extension OnboardingPage3 {
    
    var descriptionSection: some View {
        VStack(spacing: 5) {
            Text("Snap a photo of any flyer or poster. We'll extract all the details automatically.")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            
            Text("Or enter the event details manually")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "55564F"))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Previews

#Preview("Page 3") {
    OnboardingPage3()
        .background(Color(hex: "F8F7F1"))
}
