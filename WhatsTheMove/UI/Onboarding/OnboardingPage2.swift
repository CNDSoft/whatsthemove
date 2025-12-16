//
//  OnboardingPage2.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingPage2: View {
    
    var body: some View {
        VStack(spacing: 20) {
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

private extension OnboardingPage2 {
    
    var titleSection: some View {
        VStack(spacing: 0) {
            Text("Never lose track")
                .font(.rubik(.bold, size: 32))
                .foregroundColor(Color(hex: "11104B"))
                .tracking(-0.64)
            
            Text("of events again")
                .font(.rubik(.bold, size: 32))
                .foregroundColor(Color(hex: "11104B"))
                .tracking(-0.64)
        }
    }
}

// MARK: - Illustration Section

private extension OnboardingPage2 {
    
    var illustrationSection: some View {
        Image("onboarding2")
            .resizable()
            .scaledToFit()
            .frame(height: 240)
    }
}

// MARK: - Description Section

private extension OnboardingPage2 {
    
    var descriptionSection: some View {
        Text("Save events from Instagram, flyers, and websites in one organized place")
            .font(.rubik(.regular, size: 16))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .lineSpacing(3)
    }
}

// MARK: - Previews

#Preview("Page 2") {
    OnboardingPage2()
        .background(Color(hex: "F8F7F1"))
}
