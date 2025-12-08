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
}

// MARK: - UserInteractorError

enum UserInteractorError: LocalizedError {
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        }
    }
}
