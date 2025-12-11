//
//  OnboardingPage6.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingPage6: View {
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            titleSection
                .padding(.horizontal, 40)
            
            eventCardSection
            
            benefitsSection
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Title Section

private extension OnboardingPage6 {
    
    var titleSection: some View {
        Text("Turn on notifications")
            .font(.rubik(.bold, size: 32))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .tracking(-0.64)
    }
}

// MARK: - Event Card Section

private extension OnboardingPage6 {
    
    var eventCardSection: some View {
        Image("onboarding6_1")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Benefits Section

private extension OnboardingPage6 {
    
    var benefitsSection: some View {
        Image("onboarding6_2")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Previews

#Preview("Page 6") {
    OnboardingPage6()
        .background(Color(hex: "F8F7F1"))
}
