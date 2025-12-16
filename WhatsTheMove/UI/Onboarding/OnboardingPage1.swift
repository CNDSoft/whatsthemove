//
//  OnboardingPage1.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct OnboardingPage1: View {
    
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

private extension OnboardingPage1 {
    
    var titleSection: some View {
        Text("Ever see a cool public event and forget about it?")
            .font(.rubik(.bold, size: 32))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .tracking(-0.64)
            .lineSpacing(2)
    }
}

// MARK: - Illustration Section

private extension OnboardingPage1 {
    
    var illustrationSection: some View {
        Image("onbording1")
            .resizable()
            .scaledToFit()
            .frame(width: 295, height: 130)
    }
}

// MARK: - Description Section

private extension OnboardingPage1 {
    
    var descriptionSection: some View {
        Text("You screenshot flyers, save Instagram posts, and tell yourself you'll remember... but life gets busy.")
            .font(.rubik(.regular, size: 16))
            .foregroundColor(Color(hex: "11104B"))
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .padding(.horizontal, 30)
    }
}

// MARK: - Previews

#Preview("Page 1") {
    OnboardingPage1()
        .background(Color(hex: "F8F7F1"))
}
