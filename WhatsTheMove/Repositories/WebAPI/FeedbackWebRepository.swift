//
//  FeedbackWebRepository.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/24/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import FirebaseFirestore

protocol FeedbackWebRepository {
    func submitFeedback(_ feedback: Feedback) async throws
}

struct RealFeedbackWebRepository: FeedbackWebRepository {
    
    private let db = Firestore.firestore()
    private let collectionName = "feedbacks"
    
    func submitFeedback(_ feedback: Feedback) async throws {
        print("RealFeedbackWebRepository - Submitting feedback: \(feedback.id)")
        
        try await db.collection(collectionName)
            .document(feedback.id)
            .setData(feedback.toDictionary())
        
        print("RealFeedbackWebRepository - Feedback submitted successfully")
    }
}

struct StubFeedbackWebRepository: FeedbackWebRepository {
    
    func submitFeedback(_ feedback: Feedback) async throws {
        print("StubFeedbackWebRepository - Submit feedback stub")
    }
}

