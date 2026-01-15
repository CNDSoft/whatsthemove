//
//  AppState.swift
//  Whats The Move
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

struct AppState: Equatable {
    var routing = ViewRouting()
    var system = System()
    var permissions = Permissions()
    var userData = UserData()
}

extension AppState {
    struct ViewRouting: Equatable {
        var countriesList = CountriesList.Routing()
        var countryDetails = CountryDetails.Routing()
        var showAddEventFromShare: Bool = false
        var sharedEventData: SharedEventData? = nil
        var selectedTab: MainTab = .home
        var notificationViewOpenedFrom: MainTab? = nil
    }
    
    enum MainTab: Equatable {
        case home
        case saved
        case profile
    }
}

extension AppState {
    struct System: Equatable {
        var isActive: Bool = false
        var keyboardHeight: CGFloat = 0
        var showLaunchScreen: Bool = true
        var isLoadingInitialData: Bool = true
    }
}

extension AppState {
    struct UserData: Equatable {
        var isAuthenticated: Bool = false
        var hasCompletedOnboarding: Bool = false
        var userId: String?
        var email: String?
        var firstName: String?
        var lastName: String?
        var phoneNumber: String?
        var events: [Event] = []
        var starredEventIds: Set<String> = []
        var lastSavedEventId: String?
        var notificationTappedEventId: String?
        var connectedCalendarType: CalendarType? = {
            if let rawValue = UserDefaults.standard.string(forKey: "connectedCalendarType") {
                return CalendarType(rawValue: rawValue)
            }
            return nil
        }()
        var selectedCalendarIdentifier: String? = UserDefaults.standard.string(forKey: "selectedCalendarIdentifier")
        var selectedCalendarName: String? = UserDefaults.standard.string(forKey: "selectedCalendarName")
        var calendarSyncEnabled: Bool = UserDefaults.standard.bool(forKey: "calendarSyncEnabled")
        var lastCalendarSyncDate: Date? = UserDefaults.standard.object(forKey: "lastCalendarSyncDate") as? Date
        var includeSourceLinksInCalendar: Bool = UserDefaults.standard.object(forKey: "includeSourceLinksInCalendar") as? Bool ?? true
        var notificationPreferences: NotificationPreferences = NotificationPreferences()
        var notifications: [NotificationItem] = []
        var fcmToken: String?
        var analyticsEnabled: Bool = UserDefaults.standard.object(forKey: "analyticsEnabled") as? Bool ?? false
        var timezone: String = TimeZone.current.identifier
    }
}

extension AppState {
    struct Permissions: Equatable {
        var push: Permission.Status = .unknown
        var camera: Permission.Status = .unknown
        var calendar: Permission.Status = .unknown
    }

    static func permissionKeyPath(for permission: Permission) -> WritableKeyPath<AppState, Permission.Status> {
        let pathToPermissions = \AppState.permissions
        switch permission {
        case .pushNotifications:
            return pathToPermissions.appending(path: \.push)
        case .camera:
            return pathToPermissions.appending(path: \.camera)
        case .calendar:
            return pathToPermissions.appending(path: \.calendar)
        }
    }
}

func == (lhs: AppState, rhs: AppState) -> Bool {
    return lhs.routing == rhs.routing
        && lhs.system == rhs.system
        && lhs.permissions == rhs.permissions
        && lhs.userData == rhs.userData
}
