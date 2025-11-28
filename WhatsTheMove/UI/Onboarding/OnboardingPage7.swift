//
//  OnboardingPage7.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingPage7: View {
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
                .frame(height: 80)
            
            headerSection
            
            featureCards
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .background(backgroundPattern)
    }
}

// MARK: - Background Pattern

private extension OnboardingPage7 {
    
    var backgroundPattern: some View {
        Image("auth-background")
            .resizable()
            .scaledToFill()
    }
}

// MARK: - Header Section

private extension OnboardingPage7 {
    
    var headerSection: some View {
        VStack(spacing: 20) {
            Image("onboarding7_1")
                .resizable()
                .scaledToFit()
        }
    }
}

// MARK: - Feature Cards

private extension OnboardingPage7 {
    
    var featureCards: some View {
        Image("onboarding7_2")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Previews

#Preview("Page 7") {
    OnboardingPage7()
        .background(Color(hex: "11104B"))
}
