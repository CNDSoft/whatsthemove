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
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 100)
            
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

private extension OnboardingPage5 {
    
    var titleSection: some View {
        Text("Turn on notifications")
            .font(.rubik(.bold, size: 32))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .tracking(-0.64)
    }
}

// MARK: - Event Card Section

private extension OnboardingPage5 {
    
    var eventCardSection: some View {
        Image("onboarding5_1")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Benefits Section

private extension OnboardingPage5 {
    
    var benefitsSection: some View {
        Image("onboarding5_2")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Previews

#Preview("Page 5") {
    OnboardingPage5()
        .background(Color(hex: "F8F7F1"))
}
