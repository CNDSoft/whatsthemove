//
//  CategoriesView.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/5/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct CategoriesView: View {
    
    @Binding var selectedCategory: EventCategory?
    var onDismiss: (() -> Void)?
    var availableCategories: [EventCategory]?
    
    var body: some View {

        categoryList
        .padding(.top, 10)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.white)
    }
}

// MARK: - Subviews

private extension CategoriesView {
    
    var dragIndicator: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 100)
                .fill(Color(hex: "E8E8E8"))
                .frame(width: 80, height: 5)
            Spacer()
        }
        .padding(.bottom, 19)
    }
    
    var categoryList: some View {
        let categoriesToShow = availableCategories ?? Array(EventCategory.allCases)
        
        return VStack(spacing: 19) {
            ForEach(categoriesToShow, id: \.self) { category in
                categoryRow(category)
            }
        }
    }
    
    func categoryRow(_ category: EventCategory) -> some View {
        Button {
            selectedCategory = category
            onDismiss?()
        } label: {
            HStack(spacing: 10) {
                Image(category.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color(hex: "11104B"))
                
                Text(category.rawValue)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "11104B"))
                
                Spacer()
                
                radioIndicator(isSelected: selectedCategory == category)
            }
        }
        .buttonStyle(.plain)
    }
    
    func radioIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "11104B"), lineWidth: 1.5)
                .frame(width: 16, height: 16)
            
            if isSelected {
                Circle()
                    .fill(Color(hex: "11104B"))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        CategoriesView(
            selectedCategory: .constant(.outdoor),
            onDismiss: {
                print("CategoriesView - Dismissed")
            }
        )
    }
    .background(Color.gray.opacity(0.3))
}
