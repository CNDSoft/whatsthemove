//
//  AddEventOptionsSheet.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/9/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct AddEventOptionsSheet: View {
    
    let onManualEntryTapped: () -> Void
    let onShareFromAppTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            headerView.padding(.top, 24)
            optionsContent
        }
        .presentationBackground(Color.white)
        .preferredColorScheme(.light)
    }
}

// MARK: - Header

private extension AddEventOptionsSheet {
    
    var headerView: some View {
        HStack {
            Text("Add an event")
                .font(.rubik(.medium, size: 15))
                .foregroundColor(Color(hex: "11104B"))
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

// MARK: - Options Content

private extension AddEventOptionsSheet {
    
    var optionsContent: some View {
        VStack(spacing: 0) {
            shareFromAppButton
            enterManuallyButton
        }
    }
    
    var shareFromAppButton: some View {
        Button {
            onShareFromAppTapped()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 22)
                
                Text("Share from another app")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
    
    var enterManuallyButton: some View {
        Button {
            onManualEntryTapped()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 22)
                
                Text("Enter event details manually")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.bottom, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview {
    AddEventOptionsSheet(
        onManualEntryTapped: {},
        onShareFromAppTapped: {}
    )
    .presentationDetents([.height(140)])
    .presentationDragIndicator(.visible)
}
