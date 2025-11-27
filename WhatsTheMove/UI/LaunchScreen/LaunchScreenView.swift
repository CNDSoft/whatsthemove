//
//  LaunchScreenView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/26/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct LaunchScreenView: View {
    
    let onRegister: () -> Void
    let onSignIn: () -> Void
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                Spacer()
                
                content
                
                Spacer()
                
                actionButtons
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Content

private extension LaunchScreenView {
    
    var content: some View {
        VStack(spacing: 20) {
            logoSection
            taglineSection
        }
    }
    
    var logoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Text("wtm")
                .font(.system(size: 92, weight: .black, design: .rounded))
                .italic()
                .foregroundColor(Color(hex: "F8F7F1"))
                .tracking(-1.84)
                .lineSpacing(73 - 92)
            
            Text("What's The Move")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "11104B"))
                .padding(.horizontal, 10)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color(hex: "E7FF63"))
                )
                .rotationEffect(.degrees(-2))
                .offset(x: -10, y: 15)
        }
        .padding(.horizontal, 40)
    }
    
    var taglineSection: some View {
        Text("Save events you discover. Never run out of things to do")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(Color(hex: "F8F7F1"))
            .tracking(-0.56)
            .lineSpacing(32 - 28)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }
}

// MARK: - Action Buttons

private extension LaunchScreenView {
    
    var actionButtons: some View {
        VStack(spacing: 10) {
            PrimaryButton(
                title: "Register",
                backgroundColor: Color(hex: "4B7BE2"),
                textColor: .white,
                action: onRegister
            )
            
            PrimaryButton(
                title: "Sign In",
                backgroundColor: Color(hex: "F8F7F1"),
                textColor: Color(hex: "11104B"),
                action: onSignIn
            )
        }
    }
}

// MARK: - Background

private extension LaunchScreenView {
    
    var backgroundGradient: some View {
        ZStack {
            Color(hex: "11104B")
            
            GeometryReader { geometry in
                WaveShape()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "11104B").opacity(0.8),
                                Color(hex: "1a1a5c").opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: geometry.size.width * 2.5, height: geometry.size.height * 1.5)
                    .offset(x: -geometry.size.width * 0.3, y: -geometry.size.height * 0.1)
            }
        }
    }
}

// MARK: - Wave Shape

private struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.3))
        
        path.addCurve(
            to: CGPoint(x: width * 0.4, y: height * 0.2),
            control1: CGPoint(x: width * 0.1, y: height * 0.25),
            control2: CGPoint(x: width * 0.3, y: height * 0.15)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: height * 0.5),
            control1: CGPoint(x: width * 0.5, y: height * 0.25),
            control2: CGPoint(x: width * 0.6, y: height * 0.4)
        )
        
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.7),
            control1: CGPoint(x: width * 0.8, y: height * 0.6),
            control2: CGPoint(x: width * 0.9, y: height * 0.7)
        )
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Primary Button

private struct PrimaryButton: View {
    let title: String
    let backgroundColor: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(backgroundColor)
                )
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

#Preview("iPhone 15 Pro") {
    LaunchScreenView(
        onRegister: {
            print("Register tapped")
        },
        onSignIn: {
            print("Sign In tapped")
        }
    )
    .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
    .previewDisplayName("iPhone 15 Pro")
}

#Preview("iPhone SE") {
    LaunchScreenView(
        onRegister: {
            print("Register tapped")
        },
        onSignIn: {
            print("Sign In tapped")
        }
    )
    .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
    .previewDisplayName("iPhone SE")
}

#Preview("iPhone 15 Pro Max") {
    LaunchScreenView(
        onRegister: {
            print("Register tapped")
        },
        onSignIn: {
            print("Sign In tapped")
        }
    )
    .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro Max"))
    .previewDisplayName("iPhone 15 Pro Max")
}

