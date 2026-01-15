//
//  ImageSourceSheetView.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import UIKit

struct ImageSourceSheetView: View {
    
    var onCameraTapped: (() -> Void)?
    var onPhotoLibraryTapped: (() -> Void)?
    
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add an event")
                .font(.rubik(.medium, size: 15))
                .foregroundColor(Color(hex: "11104B"))
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
                .padding(.top, 12)
            
            if isCameraAvailable {
                Button {
                    onCameraTapped?()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "11104B"))
                            .frame(width: 22)
                        
                        Text("Take a picture of an event flyer or poster")
                            .font(.rubik(.regular, size: 14))
                            .foregroundColor(Color(hex: "11104B"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            Button {
                onPhotoLibraryTapped?()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "11104B"))
                        .frame(width: 22)
                    
                    Text("Choose from photo library")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }
}

// MARK: - Preview

#Preview {
    ImageSourceSheetView(
        onCameraTapped: {
            print("ImageSourceSheetView - Camera tapped")
        },
        onPhotoLibraryTapped: {
            print("ImageSourceSheetView - Photo library tapped")
        }
    )
}
