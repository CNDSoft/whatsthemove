//
//  LocationSearchService.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/9/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation
import MapKit
import Combine

@MainActor
final class LocationSearchService: NSObject, ObservableObject {
    
    @Published var searchQuery: String = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    
    private let searchCompleter: MKLocalSearchCompleter
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        self.searchCompleter = MKLocalSearchCompleter()
        super.init()
        
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        
        setupSearchObserver()
    }
    
    private func setupSearchObserver() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        searchCompleter.queryFragment = query
    }
    
    func selectLocation(_ completion: MKLocalSearchCompletion) -> String {
        let title = completion.title
        let subtitle = completion.subtitle
        
        if subtitle.isEmpty {
            return title
        } else {
            return "\(title), \(subtitle)"
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.searchResults = completer.results
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            print("LocationSearchService - Search failed with error: \(error.localizedDescription)")
            self.searchResults = []
        }
    }
}
