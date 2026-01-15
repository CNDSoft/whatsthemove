//
//  Font+Rubik.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 11/27/2025.
//  Copyright © 2025 Cem Sertkaya. All rights reserved.
//

import SwiftUI

extension Font {
    enum Rubik {
        case light
        case regular
        case medium
        case semiBold
        case bold
        case extraBold
        case black
        
        case lightItalic
        case italic
        case mediumItalic
        case semiBoldItalic
        case boldItalic
        case extraBoldItalic
        case blackItalic
        
        var name: String {
            switch self {
            case .light: return "Rubik-Light"
            case .regular: return "Rubik-Regular"
            case .medium: return "Rubik-Medium"
            case .semiBold: return "Rubik-SemiBold"
            case .bold: return "Rubik-Bold"
            case .extraBold: return "Rubik-ExtraBold"
            case .black: return "Rubik-Black"
            case .lightItalic: return "Rubik-LightItalic"
            case .italic: return "Rubik-Italic"
            case .mediumItalic: return "Rubik-MediumItalic"
            case .semiBoldItalic: return "Rubik-SemiBoldItalic"
            case .boldItalic: return "Rubik-BoldItalic"
            case .extraBoldItalic: return "Rubik-ExtraBoldItalic"
            case .blackItalic: return "Rubik-BlackItalic"
            }
        }
    }
    
    static func rubik(_ style: Rubik, size: CGFloat) -> Font {
        let fontName = style.name
        
        #if DEBUG
        if UIFont(name: fontName, size: size) == nil {
            print("Font+Rubik - Warning: Font '\(fontName)' not found, using system font as fallback")
        }
        #endif
        
        return .custom(fontName, size: size)
    }
}

