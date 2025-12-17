//
//  UserPermissionsInteractor.swift
//  WhatsTheMove
//
//  Created by Alexey Naumov on 26.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

import Foundation
import UserNotifications
import AVFoundation
import EventKit

enum Permission {
    case pushNotifications
    case camera
    case calendar
}

extension Permission {
    enum Status: Equatable {
        case unknown
        case notRequested
        case granted
        case denied
    }
}

protocol UserPermissionsInteractor: AnyObject {
    func resolveStatus(for permission: Permission)
    func request(permission: Permission)
}

protocol SystemNotificationsSettings {
    var authorizationStatus: UNAuthorizationStatus { get }
}

protocol SystemNotificationsCenter {
    func currentSettings() async -> SystemNotificationsSettings
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
}

extension UNNotificationSettings: SystemNotificationsSettings { }
extension UNUserNotificationCenter: SystemNotificationsCenter {
    func currentSettings() async -> any SystemNotificationsSettings {
        return await notificationSettings()
    }
}

// MARK: - RealUserPermissionsInteractor

final class RealUserPermissionsInteractor: UserPermissionsInteractor {

    private let appState: Store<AppState>
    private let openAppSettings: () -> Void
    private let notificationCenter: SystemNotificationsCenter

    init(appState: Store<AppState>,
         notificationCenter: SystemNotificationsCenter = UNUserNotificationCenter.current(),
         openAppSettings: @escaping () -> Void
    ) {
        self.appState = appState
        self.notificationCenter = notificationCenter
        self.openAppSettings = openAppSettings
    }

    func resolveStatus(for permission: Permission) {
        let keyPath = AppState.permissionKeyPath(for: permission)
        let currentStatus = appState[keyPath]
        guard currentStatus == .unknown else { return }
        let appState = appState
        switch permission {
        case .pushNotifications:
            Task { @MainActor in
                appState[keyPath] = await pushNotificationsPermissionStatus()
            }
        case .camera:
            appState[keyPath] = cameraPermissionStatus()
        case .calendar:
            appState[keyPath] = calendarPermissionStatus()
        }
    }

    func request(permission: Permission) {
        let keyPath = AppState.permissionKeyPath(for: permission)
        let currentStatus = appState[keyPath]
        guard currentStatus != .denied else {
            openAppSettings()
            return
        }
        switch permission {
        case .pushNotifications:
            Task {
                await requestPushNotificationsPermission()
            }
        case .camera:
            Task {
                await requestCameraPermission()
            }
        case .calendar:
            Task {
                await requestCalendarPermission()
            }
        }
    }
}

// MARK: - Push Notifications

extension UNAuthorizationStatus {
    var map: Permission.Status {
        switch self {
        case .denied: return .denied
        case .authorized: return .granted
        case .notDetermined, .provisional, .ephemeral: return .notRequested
        @unknown default: return .notRequested
        }
    }
}

private extension RealUserPermissionsInteractor {

    func pushNotificationsPermissionStatus() async -> Permission.Status {
        return await notificationCenter
            .currentSettings()
            .authorizationStatus.map
    }

    func requestPushNotificationsPermission() async {
        let center = notificationCenter
        let isGranted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        appState[\.permissions.push] = isGranted ? .granted : .denied
    }
}

// MARK: - Camera

extension AVAuthorizationStatus {
    var map: Permission.Status {
        switch self {
        case .denied, .restricted: return .denied
        case .authorized: return .granted
        case .notDetermined: return .notRequested
        @unknown default: return .notRequested
        }
    }
}

private extension RealUserPermissionsInteractor {
    
    func cameraPermissionStatus() -> Permission.Status {
        return AVCaptureDevice.authorizationStatus(for: .video).map
    }
    
    func requestCameraPermission() async {
        let isGranted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            appState[\.permissions.camera] = isGranted ? .granted : .denied
        }
    }
}

// MARK: - Calendar

extension EKAuthorizationStatus {
    var map: Permission.Status {
        switch self {
        case .denied, .restricted: return .denied
        case .fullAccess, .writeOnly: return .granted
        case .notDetermined: return .notRequested
        @unknown default: return .notRequested
        }
    }
}

private extension RealUserPermissionsInteractor {
    
    func calendarPermissionStatus() -> Permission.Status {
        return EKEventStore.authorizationStatus(for: .event).map
    }
    
    func requestCalendarPermission() async {
        let eventStore = EKEventStore()
        do {
            let isGranted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                appState[\.permissions.calendar] = isGranted ? .granted : .denied
            }
        } catch {
            await MainActor.run {
                appState[\.permissions.calendar] = .denied
            }
        }
    }
}

// MARK: -

final class StubUserPermissionsInteractor: UserPermissionsInteractor {

    func resolveStatus(for permission: Permission) {
    }
    func request(permission: Permission) {
    }
}

