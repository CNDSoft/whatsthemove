//
//  ImageCache.swift
//  Whats The Move
//
//  Created by Cem Sertkaya on 12/8/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import SwiftUI

actor ImageCache {
    
    static let shared = ImageCache()
    
    private let cache = NSCache<NSURL, UIImage>()
    private var loadingTasks: [URL: Task<UIImage, Error>] = [:]
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100
    }
    
    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func cache(_ image: UIImage, for url: URL) {
        let cost = image.size.width * image.size.height * image.scale * image.scale
        cache.setObject(image, forKey: url as NSURL, cost: Int(cost))
    }
    
    func loadImage(from url: URL) async throws -> UIImage {
        if let cachedImage = image(for: url) {
            return cachedImage
        }
        
        if let existingTask = loadingTasks[url] {
            return try await existingTask.value
        }
        
        let task = Task<UIImage, Error> {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            guard let image = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            
            cache(image, for: url)
            loadingTasks[url] = nil
            
            return image
        }
        
        loadingTasks[url] = task
        return try await task.value
    }
    
    func clearCache() {
        cache.removeAllObjects()
        loadingTasks.removeAll()
    }
}
