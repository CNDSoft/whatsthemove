//
//  GoogleCalendarRepository.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/17/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import SwiftUI
import AuthenticationServices
import CommonCrypto

protocol GoogleCalendarRepository {
    func authenticate() async throws
    func signOut()
    func getCalendars() async throws -> [CalendarInfo]
    func createEvent(_ event: Event, in calendarId: String, includeSourceLinks: Bool) async throws -> String
    func updateEvent(_ event: Event, calendarEventId: String, in calendarId: String, includeSourceLinks: Bool) async throws
    func deleteEvent(calendarEventId: String, in calendarId: String) async throws
    func isAuthenticated() -> Bool
}

struct RealGoogleCalendarRepository: GoogleCalendarRepository {
    
    private let baseURL = "https://www.googleapis.com/calendar/v3"
    private let keychainService = "com.whatsthemove.google"
    private let accessTokenKey = "google_access_token"
    private let refreshTokenKey = "google_refresh_token"
    
    func authenticate() async throws {
        print("RealGoogleCalendarRepository - Starting authentication")
        
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            print("RealGoogleCalendarRepository - GIDClientID not found in Info.plist")
            throw CalendarSyncError.authenticationFailed
        }
        
        let redirectURI = "com.googleusercontent.apps.233558487708-59q73e1sp66691qpq33pmkkmist3vshf:/oauth2redirect"
        let scope = "https://www.googleapis.com/auth/calendar"
        
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
        var components = URLComponents(string: authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        
        guard let url = components.url else {
            throw CalendarSyncError.authenticationFailed
        }
        
        do {
            let callbackURL = try await performWebAuthentication(url: url, redirectURI: redirectURI)
            
            guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                throw CalendarSyncError.authenticationFailed
            }
            
            try await exchangeCodeForTokens(code: code, codeVerifier: codeVerifier, clientID: clientID, redirectURI: redirectURI)
            
            print("RealGoogleCalendarRepository - Authentication successful")
        } catch {
            print("RealGoogleCalendarRepository - Authentication failed: \(error)")
            throw CalendarSyncError.authenticationFailed
        }
    }
    
    func isAuthenticated() -> Bool {
        let hasToken = getAccessToken() != nil
        print("RealGoogleCalendarRepository - isAuthenticated: \(hasToken)")
        return hasToken
    }
    
    func signOut() {
        print("RealGoogleCalendarRepository - Signing out, current token: \(getAccessToken() != nil ? "exists" : "none")")
        KeychainHelper.delete(service: keychainService, account: accessTokenKey)
        KeychainHelper.delete(service: keychainService, account: refreshTokenKey)
        let stillHasToken = getAccessToken() != nil
        print("RealGoogleCalendarRepository - Google credentials cleared, token after delete: \(stillHasToken ? "still exists!" : "removed")")
    }
    
    private func performWebAuthentication(url: URL, redirectURI: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let provider = WebAuthenticationPresentationContextProvider()
            
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: redirectURI.components(separatedBy: ":").first
            ) { callbackURL, error in
                _ = provider
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let callbackURL = callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: CalendarSyncError.authenticationFailed)
                }
            }
            
            session.presentationContextProvider = provider
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
    
    private func exchangeCodeForTokens(code: String, codeVerifier: String, clientID: String, redirectURI: String) async throws {
        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "code": code,
            "client_id": clientID,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code",
            "code_verifier": codeVerifier
        ]
        
        let body = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CalendarSyncError.authenticationFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        saveAccessToken(tokenResponse.access_token)
        
        if let refreshToken = tokenResponse.refresh_token {
            saveRefreshToken(refreshToken)
        }
    }
    
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &buffer)
        }
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    func getCalendars() async throws -> [CalendarInfo] {
        print("RealGoogleCalendarRepository - Fetching calendars")
        
        guard let accessToken = getAccessToken() else {
            throw CalendarSyncError.authenticationFailed
        }
        
        let url = URL(string: "\(baseURL)/users/me/calendarList")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CalendarSyncError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            if httpResponse.statusCode == 401 {
                throw CalendarSyncError.authenticationFailed
            }
            
            guard httpResponse.statusCode == 200 else {
                throw CalendarSyncError.networkError(NSError(domain: "HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode))
            }
            
            let json = try JSONDecoder().decode(GoogleCalendarListResponse.self, from: data)
            
            let calendars = json.items.filter { $0.accessRole == "owner" || $0.accessRole == "writer" }.map { item in
                CalendarInfo(
                    id: item.id,
                    title: item.summary,
                    source: "Google",
                    color: parseColor(item.backgroundColor),
                    type: .google,
                    allowsModification: item.accessRole == "owner" || item.accessRole == "writer"
                )
            }
            
            print("RealGoogleCalendarRepository - Found \(calendars.count) calendars")
            return calendars
        } catch {
            print("RealGoogleCalendarRepository - Failed to fetch calendars: \(error)")
            throw CalendarSyncError.networkError(error)
        }
    }
    
    func createEvent(_ event: Event, in calendarId: String, includeSourceLinks: Bool) async throws -> String {
        print("RealGoogleCalendarRepository - Creating event: \(event.name)")
        
        guard let accessToken = getAccessToken() else {
            throw CalendarSyncError.authenticationFailed
        }
        
        let url = URL(string: "\(baseURL)/calendars/\(calendarId)/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let googleEvent = convertToGoogleEvent(event, includeSourceLinks: includeSourceLinks)
        request.httpBody = try JSONEncoder().encode(googleEvent)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CalendarSyncError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            if httpResponse.statusCode == 401 {
                throw CalendarSyncError.authenticationFailed
            }
            
            guard httpResponse.statusCode == 200 else {
                throw CalendarSyncError.eventCreationFailed
            }
            
            let createdEvent = try JSONDecoder().decode(GoogleEventResponse.self, from: data)
            print("RealGoogleCalendarRepository - Event created with ID: \(createdEvent.id)")
            return createdEvent.id
        } catch {
            print("RealGoogleCalendarRepository - Failed to create event: \(error)")
            throw CalendarSyncError.networkError(error)
        }
    }
    
    func updateEvent(_ event: Event, calendarEventId: String, in calendarId: String, includeSourceLinks: Bool) async throws {
        print("RealGoogleCalendarRepository - Updating event: \(calendarEventId)")
        
        guard let accessToken = getAccessToken() else {
            throw CalendarSyncError.authenticationFailed
        }
        
        let url = URL(string: "\(baseURL)/calendars/\(calendarId)/events/\(calendarEventId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let googleEvent = convertToGoogleEvent(event, includeSourceLinks: includeSourceLinks)
        request.httpBody = try JSONEncoder().encode(googleEvent)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CalendarSyncError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            if httpResponse.statusCode == 401 {
                throw CalendarSyncError.authenticationFailed
            }
            
            guard httpResponse.statusCode == 200 else {
                throw CalendarSyncError.eventCreationFailed
            }
            
            print("RealGoogleCalendarRepository - Event updated successfully")
        } catch {
            print("RealGoogleCalendarRepository - Failed to update event: \(error)")
            throw CalendarSyncError.networkError(error)
        }
    }
    
    func deleteEvent(calendarEventId: String, in calendarId: String) async throws {
        print("RealGoogleCalendarRepository - Deleting event: \(calendarEventId)")
        
        guard let accessToken = getAccessToken() else {
            throw CalendarSyncError.authenticationFailed
        }
        
        let url = URL(string: "\(baseURL)/calendars/\(calendarId)/events/\(calendarEventId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CalendarSyncError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            if httpResponse.statusCode == 401 {
                throw CalendarSyncError.authenticationFailed
            }
            
            guard httpResponse.statusCode == 204 else {
                throw CalendarSyncError.eventCreationFailed
            }
            
            print("RealGoogleCalendarRepository - Event deleted successfully")
        } catch {
            print("RealGoogleCalendarRepository - Failed to delete event: \(error)")
            throw CalendarSyncError.networkError(error)
        }
    }
    
    private func convertToGoogleEvent(_ event: Event, includeSourceLinks: Bool) -> GoogleEventRequest {
        let startDate: Date
        if let startTime = event.startTime {
            startDate = combineDateAndTime(date: event.eventDate, time: startTime)
        } else {
            startDate = event.eventDate
        }
        
        let endDate: Date
        if let endTime = event.endTime {
            endDate = combineDateAndTime(date: event.eventDate, time: endTime)
        } else {
            endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        }
        
        var description = ""
        if let notes = event.notes {
            description += notes + "\n\n"
        }
        if includeSourceLinks, let urlLink = event.urlLink {
            description += "Event Link: \(urlLink)"
        }
        
        let start: GoogleEventDateTime
        let end: GoogleEventDateTime
        
        if event.startTime == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            start = GoogleEventDateTime(date: formatter.string(from: startDate), dateTime: nil, timeZone: nil)
            end = GoogleEventDateTime(date: formatter.string(from: endDate), dateTime: nil, timeZone: nil)
        } else {
            let formatter = ISO8601DateFormatter()
            start = GoogleEventDateTime(date: nil, dateTime: formatter.string(from: startDate), timeZone: TimeZone.current.identifier)
            end = GoogleEventDateTime(date: nil, dateTime: formatter.string(from: endDate), timeZone: TimeZone.current.identifier)
        }
        
        return GoogleEventRequest(
            summary: event.name,
            location: event.location,
            description: description.isEmpty ? nil : description,
            start: start,
            end: end
        )
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? date
    }
    
    private func parseColor(_ hexColor: String) -> Color {
        let hex = hexColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        r = (int >> 16) & 0xFF
        g = (int >> 8) & 0xFF
        b = int & 0xFF
        return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
    
    private func getAccessToken() -> String? {
        return KeychainHelper.load(service: keychainService, account: accessTokenKey)
    }
    
    private func saveAccessToken(_ token: String) {
        KeychainHelper.save(service: keychainService, account: accessTokenKey, data: token)
    }
    
    private func getRefreshToken() -> String? {
        return KeychainHelper.load(service: keychainService, account: refreshTokenKey)
    }
    
    private func saveRefreshToken(_ token: String) {
        KeychainHelper.save(service: keychainService, account: refreshTokenKey, data: token)
    }
}

struct StubGoogleCalendarRepository: GoogleCalendarRepository {
    
    func authenticate() async throws {
    }
    
    func signOut() {
    }
    
    func isAuthenticated() -> Bool {
        return true
    }
    
    func getCalendars() async throws -> [CalendarInfo] {
        return [
            CalendarInfo(id: "stub-google-1", title: "Google Calendar", source: "Google", color: .blue, type: .google),
            CalendarInfo(id: "stub-google-2", title: "Personal", source: "Google", color: .green, type: .google)
        ]
    }
    
    func createEvent(_ event: Event, in calendarId: String, includeSourceLinks: Bool) async throws -> String {
        return "stub-google-event-id"
    }
    
    func updateEvent(_ event: Event, calendarEventId: String, in calendarId: String, includeSourceLinks: Bool) async throws {
    }
    
    func deleteEvent(calendarEventId: String, in calendarId: String) async throws {
    }
}

struct GoogleCalendarListResponse: Codable {
    let items: [GoogleCalendarItem]
}

struct GoogleCalendarItem: Codable {
    let id: String
    let summary: String
    let backgroundColor: String
    let accessRole: String
}

struct GoogleEventRequest: Codable {
    let summary: String
    let location: String?
    let description: String?
    let start: GoogleEventDateTime
    let end: GoogleEventDateTime
}

struct GoogleEventDateTime: Codable {
    let date: String?
    let dateTime: String?
    let timeZone: String?
}

struct GoogleEventResponse: Codable {
    let id: String
}

struct TokenResponse: Codable {
    let access_token: String
    let refresh_token: String?
    let expires_in: Int
    let token_type: String
}

class KeychainHelper {
    
    static func save(service: String, account: String, data: String) {
        guard let data = data.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

class WebAuthenticationPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first ?? ASPresentationAnchor()
    }
}
