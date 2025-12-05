//
//  AddEventFormComponents.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

// MARK: - FormRowContainer

struct FormRowContainer<Content: View>: View {
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.white)
    }
}

// MARK: - RadioButton

struct RadioButton: View {
    
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                radioCircle
                
                Text(title)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
            }
            .padding(.leading, 6)
            .padding(.trailing, 30)
            .padding(.vertical, 6)
            .background(Color(hex: "EFEEE7"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private var radioCircle: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color(hex: "11104B") : Color.white)
                .frame(width: 24, height: 24)
            
            if !isSelected {
                Circle()
                    .stroke(Color(hex: "EFEEE7"), lineWidth: 1)
                    .frame(width: 24, height: 24)
            }
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - CompactRadioButton

struct CompactRadioButton: View {
    
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                radioCircle
                
                Text(title)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                    .lineLimit(1)
            }
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "EFEEE7"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private var radioCircle: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color(hex: "11104B") : Color.white)
                .frame(width: 24, height: 24)
            
            if !isSelected {
                Circle()
                    .stroke(Color(hex: "EFEEE7"), lineWidth: 1)
                    .frame(width: 24, height: 24)
            }
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - FormFieldLabel

struct FormFieldLabel: View {
    
    let text: String
    
    var body: some View {
        Text(text)
            .font(.rubik(.medium, size: 15))
            .foregroundColor(Color(hex: "11104B"))
    }
}

// MARK: - FormFieldValue

struct FormFieldValue: View {
    
    let text: String
    
    var body: some View {
        Text(text)
            .font(.rubik(.regular, size: 14))
            .foregroundColor(Color(hex: "55564F"))
    }
}

// MARK: - CapsuleInputField

struct CapsuleInputField<Content: View>: View {
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 400)
                    .stroke(Color(hex: "EFEEE7"), lineWidth: 1)
            )
    }
}

// MARK: - CapsuleDropdown

struct CapsuleDropdown: View {
    
    let text: String
    let iconName: String?
    let action: () -> Void
    
    init(text: String, iconName: String? = nil, action: @escaping () -> Void) {
        self.text = text
        self.iconName = iconName
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let iconName = iconName {
                    Image(iconName)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color(hex: "11104B"))
                }
                
                Text(text)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "55564F"))
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "55564F"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(hex: "EFEEE7"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("RadioButton") {
    VStack(spacing: 20) {
        RadioButton(title: "Free", isSelected: true) {}
        RadioButton(title: "Paid", isSelected: false) {}
    }
    .padding()
}

#Preview("CompactRadioButton") {
    HStack(spacing: 8) {
        CompactRadioButton(title: "Interested", isSelected: true) {}
        CompactRadioButton(title: "Going", isSelected: false) {}
        CompactRadioButton(title: "Waitlisted", isSelected: false) {}
    }
    .padding()
}
