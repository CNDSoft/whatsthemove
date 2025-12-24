//
//  Currency.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/24/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

enum Currency {
    static let symbol: String = "₦"
    static let code: String = "NGN"
    static let name: String = "Nigerian Naira"
    
    static func format(amount: Double) -> String {
        return "\(symbol)\(Int(amount))"
    }
    
    static func format(amount: Int) -> String {
        return "\(symbol)\(amount)"
    }
}

