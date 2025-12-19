//
//  UserInteractor.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/8/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

protocol UserInteractor {
    func toggleStarredEvent(eventId: String) async throws
    func isEventStarred(eventId: String) -> Bool
    func loadStarredEventIds() async throws
    func updateUserProfile(firstName: String, lastName: String, email: String, phoneNumber: String?) async throws
}

struct RealUserInteractor: UserInteractor {
    
    let appState: Store<AppState>
    let userWebRepository: UserWebRepository
    
    func toggleStarredEvent(eventId: String) async throws {
        print("RealUserInteractor - Toggling starred event: \(eventId)")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            throw UserInteractorError.userNotAuthenticated
        }
        
        try await userWebRepository.toggleStarredEvent(userId: userId, eventId: eventId)
        
        await MainActor.run {
            var starredIds = appState[\.userData.starredEventIds]
            if starredIds.contains(eventId) {
                starredIds.remove(eventId)
                print("RealUserInteractor - Removed event from starred")
            } else {
                starredIds.insert(eventId)
                print("RealUserInteractor - Added event to starred")
            }
            appState[\.userData.starredEventIds] = starredIds
        }
        
        print("RealUserInteractor - Starred event toggled successfully")
    }
    
    func isEventStarred(eventId: String) -> Bool {
        return appState[\.userData.starredEventIds].contains(eventId)
    }
    
    func loadStarredEventIds() async throws {
        print("RealUserInteractor - Loading starred event IDs")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            print("RealUserInteractor - No user ID found")
            return
        }
        
        let starredEventIds = try await userWebRepository.getStarredEventIds(userId: userId)
        
        await MainActor.run {
            appState[\.userData.starredEventIds] = Set(starredEventIds)
        }
        
        print("RealUserInteractor - Loaded \(starredEventIds.count) starred events")
    }
    
    func updateUserProfile(firstName: String, lastName: String, email: String, phoneNumber: String?) async throws {
        print("RealUserInteractor - Updating user profile")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            throw UserInteractorError.userNotAuthenticated
        }
        
        guard var user = try await userWebRepository.getUser(id: userId) else {
            throw UserInteractorError.userNotFound
        }
        
        let updatedUser = User(
            id: user.id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            ageRange: user.ageRange,
            phoneNumber: phoneNumber,
            starredEventIds: user.starredEventIds,
            notificationPreferences: user.notificationPreferences,
            fcmToken: user.fcmToken,
            createdAt: user.createdAt,
            updatedAt: Date()
        )
        
        try await userWebRepository.updateUser(updatedUser)
        
        await MainActor.run {
            appState[\.userData.firstName] = firstName
            appState[\.userData.lastName] = lastName
            appState[\.userData.email] = email
            appState[\.userData.phoneNumber] = phoneNumber
        }
        
        print("RealUserInteractor - User profile updated successfully")
    }
}

struct StubUserInteractor: UserInteractor {
    
    func toggleStarredEvent(eventId: String) async throws {
        print("StubUserInteractor - Toggle starred event stub")
    }
    
    func isEventStarred(eventId: String) -> Bool {
        print("StubUserInteractor - Is event starred stub")
        return false
    }
    
    func loadStarredEventIds() async throws {
        print("StubUserInteractor - Load starred event IDs stub")
    }
    
    func updateUserProfile(firstName: String, lastName: String, email: String, phoneNumber: String?) async throws {
        print("StubUserInteractor - Update user profile stub")
    }
}

// MARK: - UserInteractorError

enum UserInteractorError: LocalizedError {
    case userNotAuthenticated
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .userNotFound:
            return "User not found"
        }
    }
}
