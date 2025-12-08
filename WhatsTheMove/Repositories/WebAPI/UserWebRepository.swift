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
}



