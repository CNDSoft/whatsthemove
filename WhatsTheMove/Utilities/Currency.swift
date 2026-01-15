//
//  Currency.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 12/24/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

enum Currency {
    static let imageName: String = "Money"
    static let code: String = "NGN"
    static let name: String = "Nigerian Naira"
    
    static func format(amount: Double) -> String {
        return "\(Int(amount))"
    }
    
    static func format(amount: Int) -> String {
        return "\(amount)"
    }
}

