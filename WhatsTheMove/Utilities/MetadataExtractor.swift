//
//  MetadataExtractor.swift
//  WhatsTheMove
//
//  Created by Cem Sertkaya on 12/10/24.
//  Copyright © 2024 Cem Sertkaya. All rights reserved.
//

import Foundation

struct ExtractedMetadata {
    var title: String?
    var description: String?
    var imageUrl: String?
}

enum MetadataExtractor {
    
    static func extractMetadata(from url: URL) async throws -> ExtractedMetadata {
        let host = url.host?.lowercased() ?? ""
        
        if host.contains("instagram.com") {
            return try await extractInstagramMetadata(from: url)
        } else if host.contains("facebook.com") || host.contains("fb.com") {
            return try await extractFacebookMetadata(from: url)
        } else if host.contains("eventbrite.com") {
            return try await extractEventbriteMetadata(from: url)
        } else if host.contains("tiktok.com") {
            return try await extractTikTokMetadata(from: url)
        } else {
            return try await extractGenericMetadata(from: url)
        }
    }
    
    private static func extractInstagramMetadata(from url: URL) async throws -> ExtractedMetadata {
        let html = try await fetchHTML(from: url)
        var metadata = ExtractedMetadata()
        
        metadata.title = extractOpenGraphTag(from: html, property: "og:title")
        metadata.description = extractOpenGraphTag(from: html, property: "og:description")
        metadata.imageUrl = extractOpenGraphTag(from: html, property: "og:image")
        
        return metadata
    }
    
    private static func extractFacebookMetadata(from url: URL) async throws -> ExtractedMetadata {
        let html = try await fetchHTML(from: url)
        var metadata = ExtractedMetadata()
        
        metadata.title = extractOpenGraphTag(from: html, property: "og:title")
        metadata.description = extractOpenGraphTag(from: html, property: "og:description")
        metadata.imageUrl = extractOpenGraphTag(from: html, property: "og:image")
        
        return metadata
    }
    
    private static func extractEventbriteMetadata(from url: URL) async throws -> ExtractedMetadata {
        let html = try await fetchHTML(from: url)
        var metadata = ExtractedMetadata()
        
        metadata.title = extractOpenGraphTag(from: html, property: "og:title")
        metadata.description = extractOpenGraphTag(from: html, property: "og:description")
        metadata.imageUrl = extractOpenGraphTag(from: html, property: "og:image")
        
        return metadata
    }
    
    private static func extractTikTokMetadata(from url: URL) async throws -> ExtractedMetadata {
        let html = try await fetchHTML(from: url)
        var metadata = ExtractedMetadata()
        
        metadata.title = extractOpenGraphTag(from: html, property: "og:title")
        metadata.description = extractOpenGraphTag(from: html, property: "og:description")
        metadata.imageUrl = extractOpenGraphTag(from: html, property: "og:image")
        
        return metadata
    }
    
    private static func extractGenericMetadata(from url: URL) async throws -> ExtractedMetadata {
        let html = try await fetchHTML(from: url)
        var metadata = ExtractedMetadata()
        
        metadata.title = extractOpenGraphTag(from: html, property: "og:title")
            ?? extractMetaTag(from: html, name: "title")
            ?? extractTitleTag(from: html)
        
        metadata.description = extractOpenGraphTag(from: html, property: "og:description")
            ?? extractMetaTag(from: html, name: "description")
        
        metadata.imageUrl = extractOpenGraphTag(from: html, property: "og:image")
        
        return metadata
    }
    
    private static func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MetadataExtractionError.invalidResponse
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw MetadataExtractionError.invalidEncoding
        }
        
        return html
    }
    
    private static func extractOpenGraphTag(from html: String, property: String) -> String? {
        let pattern = "<meta[^>]*property=[\"']\(property)[\"'][^>]*content=[\"']([^\"']*)[\"'][^>]*>"
        let alternatePattern = "<meta[^>]*content=[\"']([^\"']*)[\"'][^>]*property=[\"']\(property)[\"'][^>]*>"
        
        if let value = extractWithRegex(from: html, pattern: pattern) {
            return value
        }
        
        return extractWithRegex(from: html, pattern: alternatePattern)
    }
    
    private static func extractMetaTag(from html: String, name: String) -> String? {
        let pattern = "<meta[^>]*name=[\"']\(name)[\"'][^>]*content=[\"']([^\"']*)[\"'][^>]*>"
        let alternatePattern = "<meta[^>]*content=[\"']([^\"']*)[\"'][^>]*name=[\"']\(name)[\"'][^>]*>"
        
        if let value = extractWithRegex(from: html, pattern: pattern) {
            return value
        }
        
        return extractWithRegex(from: html, pattern: alternatePattern)
    }
    
    private static func extractTitleTag(from html: String) -> String? {
        let pattern = "<title[^>]*>([^<]*)</title>"
        return extractWithRegex(from: html, pattern: pattern)
    }
    
    private static func extractWithRegex(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1 else {
            return nil
        }
        
        let captureRange = match.range(at: 1)
        guard let swiftRange = Range(captureRange, in: text) else {
            return nil
        }
        
        let value = String(text[swiftRange])
        return value.isEmpty ? nil : decodeHTMLEntities(value)
    }
    
    private static func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")
        result = result.replacingOccurrences(of: "&apos;", with: "'")
        return result
    }
}

enum MetadataExtractionError: Error {
    case invalidResponse
    case invalidEncoding
}
