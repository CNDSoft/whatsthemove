//
//  AuthInteractor.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 11/27/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import Combine

protocol AuthInteractor {
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, name: String) async throws
    func signOut() async throws
    func checkAuthStatus() async -> Bool
}

struct RealAuthInteractor: AuthInteractor {
    
    let appState: Store<AppState>
    
    func signIn(email: String, password: String) async throws {
        print("RealAuthInteractor - Sign in with email: \(email)")
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        appState[\.userData.isAuthenticated] = true
        appState[\.userData.email] = email
        appState[\.userData.userId] = UUID().uuidString
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        print("RealAuthInteractor - Sign up with email: \(email), name: \(name)")
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        appState[\.userData.isAuthenticated] = true
        appState[\.userData.email] = email
        appState[\.userData.userId] = UUID().uuidString
    }
    
    func signOut() async throws {
        print("RealAuthInteractor - Sign out")
        
        appState[\.userData.isAuthenticated] = false
        appState[\.userData.email] = nil
        appState[\.userData.userId] = nil
    }
    
    func checkAuthStatus() async -> Bool {
        print("RealAuthInteractor - Checking auth status")
        return appState.value.userData.isAuthenticated
    }
}

struct StubAuthInteractor: AuthInteractor {
    
    func signIn(email: String, password: String) async throws {
        print("StubAuthInteractor - Sign in stub")
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        print("StubAuthInteractor - Sign up stub")
    }
    
    func signOut() async throws {
        print("StubAuthInteractor - Sign out stub")
    }
    
    func checkAuthStatus() async -> Bool {
        print("StubAuthInteractor - Check auth status stub")
        return false
    }
}


