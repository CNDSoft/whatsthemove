//
//  PushNotificationsHandler.swift
//  Whats The Move
//
//  Created by Alexey Naumov on 26.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//

import UserNotifications

protocol PushNotificationsHandler {
    func handleNotificationTap(userInfo: [AnyHashable: Any])
}

final class RealPushNotificationsHandler: PushNotificationsHandler {
    
    private let deepLinksHandler: DeepLinksHandler
    
    init(deepLinksHandler: DeepLinksHandler) {
        self.deepLinksHandler = deepLinksHandler
    }
    
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        print("PushNotificationsHandler - Handling notification tap")
        
        guard let payload = userInfo["aps"] as? [AnyHashable: Any],
              let countryCode = payload["country"] as? String else {
            print("PushNotificationsHandler - No country code in payload, skipping deep link")
            return
        }
        
        Task { @MainActor in
            print("PushNotificationsHandler - Opening deep link for country: \(countryCode)")
            deepLinksHandler.open(deepLink: .showCountryFlag(alpha3Code: countryCode))
        }
    }
}
