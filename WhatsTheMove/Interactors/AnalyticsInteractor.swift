//
//  AnalyticsInteractor.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/23/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import FirebaseAnalytics

protocol AnalyticsInteractor {
    func setAnalyticsEnabled(_ enabled: Bool) async throws
    func trackScreenView(screenName: String, screenClass: String)
    func trackSignUp(method: String)
    func trackLogin(method: String)
    func trackEventSaved(eventId: String, eventName: String)
    func trackEventViewed(eventId: String, eventName: String)
    func trackEventUnsaved(eventId: String, eventName: String)
}

struct RealAnalyticsInteractor: AnalyticsInteractor {
    
    let appState: Store<AppState>
    let userWebRepository: UserWebRepository
    
    func setAnalyticsEnabled(_ enabled: Bool) async throws {
        print("RealAnalyticsInteractor - Setting analytics enabled: \(enabled)")
        
        guard let userId = await MainActor.run(body: { appState[\.userData.userId] }) else {
            print("RealAnalyticsInteractor - No user ID found")
            throw AnalyticsInteractorError.userNotAuthenticated
        }
        
        Analytics.setAnalyticsCollectionEnabled(enabled)
        
        try await userWebRepository.updateAnalyticsPreference(userId: userId, enabled: enabled)
        
        await MainActor.run {
            appState[\.userData.analyticsEnabled] = enabled
        }
        
        print("RealAnalyticsInteractor - Analytics enabled set to: \(enabled)")
    }
    
    func trackScreenView(screenName: String, screenClass: String) {
        guard isAnalyticsEnabled() else { return }
        
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
        
        print("RealAnalyticsInteractor - Screen view tracked: \(screenName)")
    }
    
    func trackSignUp(method: String) {
        guard isAnalyticsEnabled() else { return }
        
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
        
        print("RealAnalyticsInteractor - Sign up tracked with method: \(method)")
    }
    
    func trackLogin(method: String) {
        guard isAnalyticsEnabled() else { return }
        
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
        
        print("RealAnalyticsInteractor - Login tracked with method: \(method)")
    }
    
    func trackEventSaved(eventId: String, eventName: String) {
        guard isAnalyticsEnabled() else { return }
        
        Analytics.logEvent("event_saved", parameters: [
            "event_id": eventId,
            "event_name": eventName
        ])
        
        print("RealAnalyticsInteractor - Event saved tracked: \(eventName)")
    }
    
    func trackEventViewed(eventId: String, eventName: String) {
        guard isAnalyticsEnabled() else { return }
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: eventId,
            AnalyticsParameterItemName: eventName,
            AnalyticsParameterContentType: "event"
        ])
        
        print("RealAnalyticsInteractor - Event viewed tracked: \(eventName)")
    }
    
    func trackEventUnsaved(eventId: String, eventName: String) {
        guard isAnalyticsEnabled() else { return }
        
        Analytics.logEvent("event_unsaved", parameters: [
            "event_id": eventId,
            "event_name": eventName
        ])
        
        print("RealAnalyticsInteractor - Event unsaved tracked: \(eventName)")
    }
    
    private func isAnalyticsEnabled() -> Bool {
        return appState[\.userData.analyticsEnabled]
    }
}

struct StubAnalyticsInteractor: AnalyticsInteractor {
    
    func setAnalyticsEnabled(_ enabled: Bool) async throws {
        print("StubAnalyticsInteractor - Set analytics enabled stub: \(enabled)")
    }
    
    func trackScreenView(screenName: String, screenClass: String) {
        print("StubAnalyticsInteractor - Track screen view stub: \(screenName)")
    }
    
    func trackSignUp(method: String) {
        print("StubAnalyticsInteractor - Track sign up stub")
    }
    
    func trackLogin(method: String) {
        print("StubAnalyticsInteractor - Track login stub")
    }
    
    func trackEventSaved(eventId: String, eventName: String) {
        print("StubAnalyticsInteractor - Track event saved stub")
    }
    
    func trackEventViewed(eventId: String, eventName: String) {
        print("StubAnalyticsInteractor - Track event viewed stub")
    }
    
    func trackEventUnsaved(eventId: String, eventName: String) {
        print("StubAnalyticsInteractor - Track event unsaved stub")
    }
}

enum AnalyticsInteractorError: LocalizedError {
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        }
    }
}

