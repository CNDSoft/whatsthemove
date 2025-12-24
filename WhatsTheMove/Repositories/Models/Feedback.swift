//
//  Feedback.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/24/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Feedback: Codable, Equatable {
    let id: String
    let userId: String
    let userEmail: String
    let userName: String
    let feedbackText: String
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        userEmail: String,
        userName: String,
        feedbackText: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.userEmail = userEmail
        self.userName = userName
        self.feedbackText = feedbackText
        self.createdAt = createdAt
    }
}

extension Feedback {
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "userEmail": userEmail,
            "userName": userName,
            "feedbackText": feedbackText,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> Feedback? {
        guard let userId = dict["userId"] as? String,
              let userEmail = dict["userEmail"] as? String,
              let userName = dict["userName"] as? String,
              let feedbackText = dict["feedbackText"] as? String,
              let createdAtTimestamp = dict["createdAt"] as? Timestamp else {
            return nil
        }
        
        return Feedback(
            id: id,
            userId: userId,
            userEmail: userEmail,
            userName: userName,
            feedbackText: feedbackText,
            createdAt: createdAtTimestamp.dateValue()
        )
    }
}

