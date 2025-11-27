//
//  LaunchScreenView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/26/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct LaunchScreenView: View {
    
    var body: some View {
        ZStack {
            Color(hex: "11104B")
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("wtm")
                    .font(.system(size: 92, weight: .black, design: .rounded))
                    .italic()
                    .foregroundColor(Color(hex: "F8F7F1"))
                    .tracking(-1.84)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "E7FF63")))
                    .scaleEffect(1.5)
            }
        }
    }
}

// MARK: - Color Extension

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews

#Preview {
    LaunchScreenView()
}

