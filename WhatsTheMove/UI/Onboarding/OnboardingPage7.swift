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
        ZStack {
            Color(hex: "11104B")
                .ignoresSafeArea()
            
            backgroundPattern
            
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 100)
                
                headerSection
                
                featureCards
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Background Pattern

private extension OnboardingPage7 {
    
    var backgroundPattern: some View {
        Image("auth-background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
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
}
