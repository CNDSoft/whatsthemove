//
//  SharedEventData.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/10/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

struct SharedEventData: Codable, Equatable {
    var title: String?
    var urlLink: String?
    var imageData: Data?
    var description: String?
    var sourceApp: String?
    
    init(
        title: String? = nil,
        urlLink: String? = nil,
        imageData: Data? = nil,
        description: String? = nil,
        sourceApp: String? = nil
    ) {
        self.title = title
        self.urlLink = urlLink
        self.imageData = imageData
        self.description = description
        self.sourceApp = sourceApp
    }
}
