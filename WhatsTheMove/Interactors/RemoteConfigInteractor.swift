//
//  RemoteConfigInteractor.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/23/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

protocol RemoteConfigInteractor {
    func fetchPrivacyPolicyText() async throws -> String
}

struct RealRemoteConfigInteractor: RemoteConfigInteractor {
    
    private let remoteConfig: RemoteConfig
    private let defaultPrivacyPolicyText: String
    
    init() {
        self.remoteConfig = RemoteConfig.remoteConfig()
        
        self.defaultPrivacyPolicyText = """
        PRIVACY POLICY
        
        Last updated: December 23, 2024
        
        This Privacy Policy describes how WhatsTheMove collects, uses, and protects your information when you use our mobile application.
        
        INFORMATION WE COLLECT
        
        We collect information that you provide directly to us, including:
        - Account information (name, email address, phone number)
        - Event information that you create or save
        - Calendar preferences and settings
        - Notification preferences
        - Analytics data (if enabled)
        
        HOW WE USE YOUR INFORMATION
        
        We use the information we collect to:
        - Provide, maintain, and improve our services
        - Send you notifications about events
        - Sync events with your calendar
        - Analyze usage patterns to improve the app
        - Communicate with you about updates and features
        
        DATA STORAGE AND SECURITY
        
        We use Firebase services to store and process your data securely. Your data is protected using industry-standard security measures.
        
        YOUR CHOICES
        
        You can:
        - Control notification preferences
        - Enable or disable analytics
        - Choose calendar sync settings
        - Delete your account and associated data
        
        CHANGES TO THIS POLICY
        
        We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last updated" date.
        
        CONTACT US
        
        If you have any questions about this Privacy Policy, please contact us through the app feedback feature.
        """
        
        let defaults: [String: NSObject] = [
            "privacy_policy_text": self.defaultPrivacyPolicyText as NSObject
        ]
        remoteConfig.setDefaults(defaults)
    }
    
    func fetchPrivacyPolicyText() async throws -> String {
        print("RealRemoteConfigInteractor - Fetching privacy policy text")
        
        do {
            let status = try await remoteConfig.fetchAndActivate()
            
            switch status {
            case .successFetchedFromRemote:
                print("RealRemoteConfigInteractor - Config fetched from remote")
            case .successUsingPreFetchedData:
                print("RealRemoteConfigInteractor - Using pre-fetched config data")
            case .error:
                print("RealRemoteConfigInteractor - Error fetching config, using defaults")
            @unknown default:
                print("RealRemoteConfigInteractor - Unknown status, using defaults")
            }
            
            let privacyText = remoteConfig.configValue(forKey: "privacy_policy_text").stringValue ?? defaultPrivacyPolicyText
            print("RealRemoteConfigInteractor - Privacy policy text fetched successfully")
            
            return privacyText
        } catch {
            print("RealRemoteConfigInteractor - Error fetching remote config: \(error.localizedDescription)")
            return defaultPrivacyPolicyText
        }
    }
}

struct StubRemoteConfigInteractor: RemoteConfigInteractor {
    
    func fetchPrivacyPolicyText() async throws -> String {
        print("StubRemoteConfigInteractor - Returning mock privacy policy text")
        
        return """
        PRIVACY POLICY (Preview)
        
        This is a preview of the privacy policy text that will be displayed in the app.
        
        The actual text will be fetched from Firebase Remote Config.
        """
    }
}

