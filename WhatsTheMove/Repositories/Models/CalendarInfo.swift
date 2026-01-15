//
//  CalendarInfo.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 12/17/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import SwiftUI

struct CalendarInfo: Identifiable, Equatable {
    let id: String
    let title: String
    let source: String
    let color: Color
    let type: CalendarType
    let allowsModification: Bool
    
    init(id: String, title: String, source: String, color: Color, type: CalendarType, allowsModification: Bool = true) {
        self.id = id
        self.title = title
        self.source = source
        self.color = color
        self.type = type
        self.allowsModification = allowsModification
    }
}
