//
//  HowToShareEventsSheet.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/10/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

struct HowToShareEventsSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                VStack(spacing: 20) {
                    illustrationView
                        .padding(.top, 20)
                    
                    stepsList
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            
            Spacer()
            
            bottomButton
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(Color(hex: "F8F7F1"))
        .presentationBackground(Color(hex: "F8F7F1"))
        .preferredColorScheme(.light)
    }
}

// MARK: - Header

private extension HowToShareEventsSheet {
    
    var headerView: some View {
        HStack(alignment: .center) {
            Text("HOW TO SHARE EVENTS")
                .font(.rubik(.extraBold, size: 20))
                .foregroundColor(Color(hex: "11104B"))
                .textCase(.uppercase)
                .lineSpacing(0)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "11104B"))
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Illustration

private extension HowToShareEventsSheet {
    
    var illustrationView: some View {
        Image("how-to-share")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 330)
            .frame(height: 128)
    }
}

// MARK: - Steps List

private extension HowToShareEventsSheet {
    
    var stepsList: some View {
        VStack(spacing: 20) {
            stepView(
                number: "1",
                title: "Find an event",
                description: "Open Instagram, Eventbrite, or any other app with an event you want to save",
                backgroundColor: nil,
                numberBackgroundColor: .white
            )
            
            stepView(
                number: "2",
                title: "Tap the share button",
                description: "Look for the share icon and tap it to open the share menu",
                backgroundColor: nil,
                numberBackgroundColor: .white
            )
            
            stepView(
                number: "3",
                title: "Select the WTM app",
                description: "Scroll through the share options and tap the WTM app to save the event",
                backgroundColor: nil,
                numberBackgroundColor: .white
            )
            
            stepView(
                number: "4",
                title: "Review and save",
                description: "We'll extract the event details automatically. Just review and save!",
                backgroundColor: Color(hex: "2D9674").opacity(0.1),
                numberBackgroundColor: Color(hex: "2D9674"),
                numberTextColor: Color(hex: "F8F7F1")
            )
            
            proTipView
        }
    }
    
    func stepView(
        number: String,
        title: String,
        description: String,
        backgroundColor: Color?,
        numberBackgroundColor: Color,
        numberTextColor: Color? = nil
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Text(number)
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(numberTextColor ?? Color(hex: "11104B"))
                    .frame(width: 22, height: 22)
                    .background(numberBackgroundColor)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.rubik(.medium, size: 15))
                        .foregroundColor(Color(hex: "11104B"))
                        .lineSpacing(0)
                    
                    Text(description)
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                        .lineSpacing(0)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(backgroundColor != nil ? 10 : 0)
        }
        .background(backgroundColor ?? Color.clear)
        .cornerRadius(10)
    }
    
    var proTipView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Text("i")
                    .font(.rubik(.semiBold, size: 14))
                    .foregroundColor(Color(hex: "F8F7F1"))
                    .frame(width: 22, height: 22)
                    .background(Color(hex: "FA7929"))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Pro Tip")
                        .font(.rubik(.medium, size: 15))
                        .foregroundColor(Color(hex: "11104B"))
                        .lineSpacing(0)
                    
                    Text("If you don't see the WTM app in the share menu, scroll to the bottom and tap \"Edit Actions\" to add it")
                        .font(.rubik(.regular, size: 14))
                        .foregroundColor(Color(hex: "11104B"))
                        .lineSpacing(0)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
        }
        .background(Color(hex: "FA7929").opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Bottom Button

private extension HowToShareEventsSheet {
    
    var bottomButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Open the Share Menu")
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "F8F7F1"))
                .lineSpacing(0)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "11104B"))
                .cornerRadius(400)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview {
    HowToShareEventsSheet()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
}
