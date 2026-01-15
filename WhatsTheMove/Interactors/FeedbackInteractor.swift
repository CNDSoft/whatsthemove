//
//  FeedbackInteractor.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 12/24/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

protocol FeedbackInteractor {
    func submitFeedback(text: String) async throws
}

struct RealFeedbackInteractor: FeedbackInteractor {
    
    let appState: Store<AppState>
    let feedbackWebRepository: FeedbackWebRepository
    
    func submitFeedback(text: String) async throws {
        print("RealFeedbackInteractor - Submitting feedback")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            throw FeedbackInteractorError.userNotAuthenticated
        }
        
        let userEmail = await MainActor.run(body: { appState[\.userData.email] }) ?? ""
        let firstName = await MainActor.run(body: { appState[\.userData.firstName] }) ?? ""
        let lastName = await MainActor.run(body: { appState[\.userData.lastName] }) ?? ""
        let userName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        let feedback = Feedback(
            userId: userId,
            userEmail: userEmail,
            userName: userName.isEmpty ? "Anonymous" : userName,
            feedbackText: text
        )
        
        try await feedbackWebRepository.submitFeedback(feedback)
        
        print("RealFeedbackInteractor - Feedback submitted successfully")
    }
}

struct StubFeedbackInteractor: FeedbackInteractor {
    
    func submitFeedback(text: String) async throws {
        print("StubFeedbackInteractor - Submit feedback stub")
    }
}

enum FeedbackInteractorError: LocalizedError {
    case userNotAuthenticated
    case submissionFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .submissionFailed:
            return "Failed to submit feedback"
        }
    }
}

