//
//  View+CalendarAlert.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/17/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

extension View {
    
    func calendarErrorAlert(isPresented: Binding<Bool>, error: CalendarSyncError?) -> some View {
        alert("Calendar Sync Error", isPresented: isPresented) {
            Button("OK", role: .cancel) { }
            
            if error == .permissionDenied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            } else {
                Text("An unknown error occurred while syncing with your calendar.")
            }
        }
    }
}

extension CalendarSyncError: Identifiable {
    var id: String {
        switch self {
        case .permissionDenied:
            return "permissionDenied"
        case .calendarNotFound:
            return "calendarNotFound"
        case .eventCreationFailed:
            return "eventCreationFailed"
        case .networkError:
            return "networkError"
        case .authenticationFailed:
            return "authenticationFailed"
        case .invalidEvent:
            return "invalidEvent"
        }
    }
}
