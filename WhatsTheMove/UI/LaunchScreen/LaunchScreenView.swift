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

// MARK: - Previews

#Preview {
    LaunchScreenView()
}


