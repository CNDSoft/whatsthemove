//
//  LaunchScreenView.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 11/26/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct LaunchScreenView: View {
    
    var body: some View {
        ZStack {
            Image("auth-background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            Image("wtm-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
        }
    }
}

// MARK: - Previews

#Preview {
    LaunchScreenView()
}


