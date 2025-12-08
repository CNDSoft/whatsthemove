//
//  UserWebRepository.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import FirebaseFirestore

protocol UserWebRepository {
    func createUser(_ user: User) async throws
    func getUser(id: String) async throws -> User?
    func updateUser(_ user: User) async throws
    func deleteUser(id: String) async throws
    func toggleStarredEvent(userId: String, eventId: String) async throws
    func getStarredEventIds(userId: String) async throws -> [String]
}

struct RealUserWebRepository: UserWebRepository {
    
    private let db = Firestore.firestore()
    private let collectionName = "users"
    
    func createUser(_ user: User) async throws {
        print("RealUserWebRepository - Creating user: \(user.id)")
        
        try await db.collection(collectionName)
            .document(user.id)
            .setData(user.toDictionary())
        
        print("RealUserWebRepository - User created successfully")
    }
    
    func getUser(id: String) async throws -> User? {
        print("RealUserWebRepository - Getting user: \(id)")
        
        let document = try await db.collection(collectionName)
            .document(id)
            .getDocument()
        
        guard document.exists, let data = document.data() else {
            print("RealUserWebRepository - User not found")
            return nil
        }
        
        let user = User.fromDictionary(data, id: id)
        print("RealUserWebRepository - User retrieved: \(user?.email ?? "nil")")
        return user
    }
    
    func updateUser(_ user: User) async throws {
        print("RealUserWebRepository - Updating user: \(user.id)")
        
        try await db.collection(collectionName)
            .document(user.id)
            .updateData(user.toDictionary())
        
        print("RealUserWebRepository - User updated successfully")
    }
    
    func deleteUser(id: String) async throws {
        print("RealUserWebRepository - Deleting user: \(id)")
        
        try await db.collection(collectionName)
            .document(id)
            .delete()
        
        print("RealUserWebRepository - User deleted successfully")
    }
    
    func toggleStarredEvent(userId: String, eventId: String) async throws {
        print("RealUserWebRepository - Toggling starred event: \(eventId) for user: \(userId)")
        
        let userRef = db.collection(collectionName).document(userId)
        let document = try await userRef.getDocument()
        
        guard document.exists else {
            throw UserWebRepositoryError.userNotFound
        }
        
        let data = document.data() ?? [:]
        var starredEventIds = (data["starredEventIds"] as? [String]) ?? []
        
        if let index = starredEventIds.firstIndex(of: eventId) {
            starredEventIds.remove(at: index)
            print("RealUserWebRepository - Removed event from starred")
        } else {
            starredEventIds.append(eventId)
            print("RealUserWebRepository - Added event to starred")
        }
        
        try await userRef.updateData(["starredEventIds": starredEventIds])
        print("RealUserWebRepository - Starred event toggled successfully")
    }
    
    func getStarredEventIds(userId: String) async throws -> [String] {
        print("RealUserWebRepository - Getting starred events for user: \(userId)")
        
        let document = try await db.collection(collectionName)
            .document(userId)
            .getDocument()
        
        guard document.exists else {
            print("RealUserWebRepository - User not found")
            return []
        }
        
        let data = document.data() ?? [:]
        let starredEventIds = (data["starredEventIds"] as? [String]) ?? []
        
        print("RealUserWebRepository - Retrieved \(starredEventIds.count) starred events")
        return starredEventIds
    }
}

struct StubUserWebRepository: UserWebRepository {
    
    func createUser(_ user: User) async throws {
        print("StubUserWebRepository - Create user stub")
    }
    
    func getUser(id: String) async throws -> User? {
        print("StubUserWebRepository - Get user stub")
        return nil
    }
    
    func updateUser(_ user: User) async throws {
        print("StubUserWebRepository - Update user stub")
    }
    
    func deleteUser(id: String) async throws {
        print("StubUserWebRepository - Delete user stub")
    }
    
    func toggleStarredEvent(userId: String, eventId: String) async throws {
        print("StubUserWebRepository - Toggle starred event stub")
    }
    
    func getStarredEventIds(userId: String) async throws -> [String] {
        print("StubUserWebRepository - Get starred event IDs stub")
        return []
    }
}

// MARK: - UserWebRepositoryError

enum UserWebRepositoryError: LocalizedError {
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        }
    }
}

