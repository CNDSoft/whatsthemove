//
//  OnboardingPage8.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingPage8: View {
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            headerSection
            
            featureCards
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .background(backgroundPattern)
    }
}

// MARK: - Background Pattern

private extension OnboardingPage8 {
    
    var backgroundPattern: some View {
        Image("auth-background")
            .resizable()
            .scaledToFill()
    }
}

// MARK: - Header Section

private extension OnboardingPage8 {
    
    var headerSection: some View {
        VStack(spacing: 20) {
            Image("onboarding8_1")
                .resizable()
                .scaledToFit()
        }
    }
}

// MARK: - Feature Cards

private extension OnboardingPage8 {
    
    var featureCards: some View {
        Image("onboarding8_2")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Previews

#Preview("Page 8") {
    OnboardingPage8()
        .background(Color(hex: "11104B"))
}
