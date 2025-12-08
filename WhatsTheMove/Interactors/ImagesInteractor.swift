//
//  ImagesInteractor.swift
//  WhatsTheMove
//
//  Created by Alexey Naumov on 09.11.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

protocol ImagesInteractor {
    func load(image: LoadableSubject<UIImage>, url: URL?)
    func preloadImages(urls: [URL]) async
}

struct RealImagesInteractor: ImagesInteractor {
    
    let webRepository: ImagesWebRepository
    
    init(webRepository: ImagesWebRepository) {
        self.webRepository = webRepository
    }
    
    func load(image: LoadableSubject<UIImage>, url: URL?) {
        guard let url else {
            image.wrappedValue = .notRequested; return
        }
        image.load {
            try await webRepository.loadImage(url: url)
        }
    }
    
    func preloadImages(urls: [URL]) async {
        print("RealImagesInteractor - Preloading \(urls.count) images")
        
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    do {
                        let _ = try await ImageCache.shared.loadImage(from: url)
                        print("RealImagesInteractor - Successfully preloaded and cached image: \(url.lastPathComponent)")
                    } catch {
                        print("RealImagesInteractor - Failed to preload image \(url.lastPathComponent): \(error.localizedDescription)")
                    }
                }
            }
        }
        
        print("RealImagesInteractor - Finished preloading \(urls.count) images")
    }
}

struct StubImagesInteractor: ImagesInteractor {
    func load(image: LoadableSubject<UIImage>, url: URL?) {
    }
    
    func preloadImages(urls: [URL]) async {
    }
}
