//
//  User.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

struct User: Codable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let ageRange: String
    let createdAt: Date
    let updatedAt: Date
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

extension User {
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "ageRange": ageRange,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> User? {
        guard let email = data["email"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let ageRange = data["ageRange"] as? String else {
            return nil
        }
        
        let createdAt = (data["createdAt"] as? Date) ?? Date()
        let updatedAt = (data["updatedAt"] as? Date) ?? Date()
        
        return User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            ageRange: ageRange,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

