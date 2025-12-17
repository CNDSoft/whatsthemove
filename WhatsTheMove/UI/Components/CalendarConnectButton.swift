//
//  CalendarConnectButton.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/17/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct CalendarConnectButton: View {
    
    let iconName: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .frame(width: 30)
                
                Text(title)
                    .font(.rubik(.regular, size: 15))
                    .foregroundColor(Color(hex: "11104B"))
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.trailing, 30)
            .padding(.leading, 40)
            .padding(.vertical, 15)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color(hex: "EFEEE7"), radius: 0, x: 0, y: 3)
            )
        }
    }
}

#Preview {
    VStack(spacing: 15) {
        CalendarConnectButton(
            iconName: "google",
            title: "Connect Google Calendar",
            action: {}
        )
        
        CalendarConnectButton(
            iconName: "apple",
            title: "Connect Apple Calendar",
            action: {}
        )
    }
    .padding(40)
    .background(Color(hex: "F8F7F1"))
}
