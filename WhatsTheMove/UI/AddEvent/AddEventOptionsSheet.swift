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
            headerView
            optionsContent
        }
        .background(Color.white)
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
                Image("share-from-app")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 22)
                
                Text("Share from another app or website")
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
                Image("enter-event")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 22)
                
                Text("Enter event details manually")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        AddEventOptionsSheet(
            onManualEntryTapped: {},
            onShareFromAppTapped: {}
        )
        .frame(height: 128)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.15), radius: 7, x: 0, y: 0)
        .padding(.horizontal, 20)
    }
}
