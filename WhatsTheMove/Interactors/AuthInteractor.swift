//
//  AuthInteractor.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import Combine
import FirebaseAuth

protocol AuthInteractor {
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, firstName: String, lastName: String, ageRange: String) async throws
    func signOut() async throws
    func checkAuthStatus() async -> Bool
    func resetPassword(email: String) async throws
    func changePassword(currentPassword: String, newPassword: String) async throws
}

struct RealAuthInteractor: AuthInteractor {
    
    let appState: Store<AppState>
    let userWebRepository: UserWebRepository
    
    func signIn(email: String, password: String) async throws {
        print("RealAuthInteractor - Sign in with email: \(email)")
        
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let firebaseUser = result.user
        
        print("RealAuthInteractor - Sign in successful for user: \(firebaseUser.uid)")
        
        let user = try await userWebRepository.getUser(id: firebaseUser.uid)
        
        await MainActor.run {
            appState[\.userData.isAuthenticated] = true
            appState[\.userData.email] = firebaseUser.email
            appState[\.userData.userId] = firebaseUser.uid
            appState[\.userData.firstName] = user?.firstName
            appState[\.userData.lastName] = user?.lastName
            appState[\.userData.phoneNumber] = user?.phoneNumber
        }
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String, ageRange: String) async throws {
        print("RealAuthInteractor - Sign up with email: \(email), name: \(firstName) \(lastName)")
        
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let firebaseUser = result.user
        
        let fullName = "\(firstName) \(lastName)"
        let changeRequest = firebaseUser.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()
        
        let now = Date()
        let user = User(
            id: firebaseUser.uid,
            email: email,
            firstName: firstName,
            lastName: lastName,
            ageRange: ageRange,
            phoneNumber: nil,
            starredEventIds: [],
            createdAt: now,
            updatedAt: now
        )
        
        try await userWebRepository.createUser(user)
        
        print("RealAuthInteractor - Sign up successful for user: \(firebaseUser.uid)")
        
        await MainActor.run {
            appState[\.userData.isAuthenticated] = true
            appState[\.userData.email] = firebaseUser.email
            appState[\.userData.userId] = firebaseUser.uid
            appState[\.userData.firstName] = firstName
            appState[\.userData.lastName] = lastName
        }
    }
    
    func signOut() async throws {
        print("RealAuthInteractor - Sign out")
        
        try Auth.auth().signOut()
        
        print("RealAuthInteractor - Sign out successful")
        
        await MainActor.run {
            appState[\.userData.isAuthenticated] = false
            appState[\.userData.email] = nil
            appState[\.userData.userId] = nil
            appState[\.userData.firstName] = nil
            appState[\.userData.lastName] = nil
            appState[\.userData.phoneNumber] = nil
        }
    }
    
    func checkAuthStatus() async -> Bool {
        print("RealAuthInteractor - Checking auth status")
        
        if let currentUser = Auth.auth().currentUser {
            print("RealAuthInteractor - User is authenticated: \(currentUser.uid)")
            
            let user = try? await userWebRepository.getUser(id: currentUser.uid)
            
            await MainActor.run {
                appState[\.userData.isAuthenticated] = true
                appState[\.userData.email] = currentUser.email
                appState[\.userData.userId] = currentUser.uid
                appState[\.userData.firstName] = user?.firstName
                appState[\.userData.lastName] = user?.lastName
                appState[\.userData.phoneNumber] = user?.phoneNumber
            }
            return true
        }
        
        print("RealAuthInteractor - No authenticated user")
        
        await MainActor.run {
            appState[\.userData.isAuthenticated] = false
            appState[\.userData.email] = nil
            appState[\.userData.userId] = nil
            appState[\.userData.firstName] = nil
            appState[\.userData.lastName] = nil
            appState[\.userData.phoneNumber] = nil
        }
        return false
    }
    
    func resetPassword(email: String) async throws {
        print("RealAuthInteractor - Reset password for email: \(email)")
        
        try await Auth.auth().sendPasswordReset(withEmail: email)
        
        print("RealAuthInteractor - Password reset email sent")
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        print("RealAuthInteractor - Changing password")
        
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw AuthInteractorError.userNotAuthenticated
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
        
        try await user.updatePassword(to: newPassword)
        
        print("RealAuthInteractor - Password changed successfully")
    }
}

struct StubAuthInteractor: AuthInteractor {
    
    func signIn(email: String, password: String) async throws {
        print("StubAuthInteractor - Sign in stub")
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String, ageRange: String) async throws {
        print("StubAuthInteractor - Sign up stub")
    }
    
    func signOut() async throws {
        print("StubAuthInteractor - Sign out stub")
    }
    
    func checkAuthStatus() async -> Bool {
        print("StubAuthInteractor - Check auth status stub")
        return false
    }
    
    func resetPassword(email: String) async throws {
        print("StubAuthInteractor - Reset password stub")
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        print("StubAuthInteractor - Change password stub")
    }
}

enum AuthInteractorError: LocalizedError {
    case userNotAuthenticated
    case invalidCurrentPassword
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .invalidCurrentPassword:
            return "Current password is incorrect"
        }
    }
}
