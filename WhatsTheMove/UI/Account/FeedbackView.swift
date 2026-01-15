//
//  FeedbackView.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 12/24/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI
import Combine

struct FeedbackView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.injected) private var injected: DIContainer
    
    @State private var feedbackText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    private let characterLimit = 1000
    
    var body: some View {
        ZStack {
            Color(hex: "F8F7F1")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                contentSection
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Thank you for your feedback! We appreciate your input.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Header Section

private extension FeedbackView {
    
    var headerSection: some View {
        HStack {
            closeButton
            
            Spacer()
            
            Text("SEND FEEDBACK")
                .font(.rubik(.extraBold, size: 20))
                .foregroundColor(Color(hex: "11104B"))
                .textCase(.uppercase)
            
            Spacer()
            
            Color.clear
                .frame(width: 38, height: 38)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
    }
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Circle()
                .fill(Color(hex: "F25454"))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
    }
}

// MARK: - Content Section

private extension FeedbackView {
    
    var contentSection: some View {
        VStack(spacing: 20) {
            descriptionText
            textEditorSection
            characterCountText
            Spacer()
            submitButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    var descriptionText: some View {
        Text("We'd love to hear your thoughts, suggestions, or any issues you've encountered. Your feedback helps us improve the app.")
            .font(.rubik(.regular, size: 14))
            .foregroundColor(Color(hex: "55564F"))
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var textEditorSection: some View {
        ZStack(alignment: .topLeading) {
            if feedbackText.isEmpty {
                Text("Share your feedback here...")
                    .font(.rubik(.regular, size: 14))
                    .foregroundColor(Color(hex: "BDBDBD"))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
            }
            
            TextEditor(text: $feedbackText)
                .font(.rubik(.regular, size: 14))
                .foregroundColor(Color(hex: "11104B"))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200, maxHeight: 300)
                .padding(.horizontal, 5)
                .padding(.vertical, 8)
                .onChange(of: feedbackText) { _, newValue in
                    if newValue.count > characterLimit {
                        feedbackText = String(newValue.prefix(characterLimit))
                    }
                }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "EFEEE7"), lineWidth: 1)
        )
        .disabled(isSubmitting)
    }
    
    var characterCountText: some View {
        HStack {
            Spacer()
            Text("\(feedbackText.count)/\(characterLimit)")
                .font(.rubik(.regular, size: 12))
                .foregroundColor(feedbackText.count >= characterLimit ? Color(hex: "F25454") : Color(hex: "55564F"))
        }
    }
    
    var submitButton: some View {
        Button {
            submitFeedback()
        } label: {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isSubmitting ? "Submitting..." : "Submit Feedback")
                    .font(.rubik(.semiBold, size: 16))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSubmitButtonDisabled ? Color(hex: "BDBDBD") : Color(hex: "4B7BE2"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isSubmitButtonDisabled)
    }
    
    var isSubmitButtonDisabled: Bool {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
    }
}

// MARK: - Side Effects

private extension FeedbackView {
    
    func submitFeedback() {
        let trimmedText = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else {
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                try await injected.interactors.feedback.submitFeedback(text: trimmedText)
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                    print("FeedbackView - Feedback submitted successfully")
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    print("FeedbackView - Error submitting feedback: \(error)")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    FeedbackView()
        .inject(DIContainer(appState: AppState(), interactors: .stub))
}

