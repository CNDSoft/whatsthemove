//
//  BellIconWithBadge.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/24/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct BellIconWithBadge: View {
    let unreadCount: Int
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("bell")
                .frame(width: 38, height: 38)
            
            if unreadCount > 0 {
                Circle()
                    .fill(Color(hex: "F25454"))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Text("\(unreadCount)")
                            .font(.rubik(.bold, size: 10))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    )
                    .offset(x: 4, y: -2)
            }
        }
    }
}

#Preview("No Badge") {
    BellIconWithBadge(unreadCount: 0)
        .padding()
        .background(Color.gray)
}

#Preview("With Badge") {
    BellIconWithBadge(unreadCount: 3)
        .padding()
        .background(Color.gray)
}

#Preview("Large Count") {
    BellIconWithBadge(unreadCount: 99)
        .padding()
        .background(Color.gray)
}

