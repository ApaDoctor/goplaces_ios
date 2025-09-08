//
//  URL+Extensions.swift
//  GoPlaces
//
//  Created by Volodymyr Piskun on 03.09.2025.
//

import Foundation

extension URL {
    
    /// Check if URL is valid for place extraction
    var isValidPlaceURL: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
    
    /// Extract domain from URL
    var domain: String? {
        return host?.lowercased()
    }
    
    /// Check if URL is from a supported platform
    var isSupportedPlatform: Bool {
        guard let domain = domain else { return false }
        
        let supportedDomains = [
            "maps.google.com",
            "goo.gl",
            "foursquare.com",
            "4sq.com",
            "yelp.com",
            "tripadvisor.com",
            "facebook.com",
            "instagram.com"
        ]
        
        return supportedDomains.contains { domain.contains($0) }
    }
}

extension String {
    
    /// Check if string is a valid URL
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.isValidPlaceURL
    }
    
    /// Clean URL string by removing tracking parameters and fragments
    var cleanedURL: String {
        guard let url = URL(string: self),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return self
        }
        
        // Remove common tracking parameters
        let trackingParams = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "fbclid", "gclid"]
        components.queryItems = components.queryItems?.filter { queryItem in
            !trackingParams.contains(queryItem.name.lowercased())
        }
        
        // Remove fragment
        components.fragment = nil
        
        return components.url?.absoluteString ?? self
    }
}

extension Optional where Wrapped == String {
    
    /// Check if optional string is nil or empty
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
    
    /// Get string value or default
    func orDefault(_ defaultValue: String) -> String {
        return self ?? defaultValue
    }
}