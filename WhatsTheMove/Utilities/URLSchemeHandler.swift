//
//  URLSchemeHandler.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 12/10/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

enum URLSchemeHandler {
    
    static func handleURL(_ url: URL) -> DeepLink? {
        guard url.scheme == "wtm" else {
            return nil
        }
        
        if url.host == "add-event" {
            return handleAddEventURL(url)
        }
        
        return nil
    }
    
    private static func handleAddEventURL(_ url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        guard let dataItem = queryItems.first(where: { $0.name == "data" }),
              let base64String = dataItem.value else {
            return nil
        }
        
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        guard let sharedData = try? decoder.decode(SharedEventData.self, from: data) else {
            return nil
        }
        
        return .addEventFromShare(sharedData)
    }
}
