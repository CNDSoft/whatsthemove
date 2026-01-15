//
//  EventActionsSheet.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 12/10/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct EventActionsSheet: View {
    
    let onEditTapped: () -> Void
    let onDeleteTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 19) {
            Spacer()
            editButton.padding(.top, 15)
            deleteButton
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var editButton: some View {
        Button {
            onEditTapped()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 20, height: 20)
                
                Text("Edit")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    private var deleteButton: some View {
        Button {
            onDeleteTapped()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "F25454"))
                    .frame(width: 20, height: 20)
                
                Text("Delete")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "F25454"))
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview {
    EventActionsSheet(
        onEditTapped: {},
        onDeleteTapped: {}
    )
    .presentationDetents([.height(113)])
}
