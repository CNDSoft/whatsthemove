//
//  View+Alert.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/8/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

extension View {
    func underDevelopmentAlert(isPresented: Binding<Bool>) -> some View {
        alert("Under Development", isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This feature is under development, will be available with next versions")
        }
    }
}
