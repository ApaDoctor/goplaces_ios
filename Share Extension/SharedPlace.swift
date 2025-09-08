//
//  SharedPlace.swift
//  Share Extension
//
//  Shared SwiftData Place Model for Share Extension
//  Created by Volodymyr Piskun on 04.09.2025.
//

import SwiftData
import Foundation

@Model
class Place {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var socialURL: String
    var addedDate: Date
    var rating: Double
    var photoURL: String?
    var phoneNumber: String?
    var website: String?
    
    // Computed properties for display
    var displayAddress: String {
        return address.isEmpty ? "Unknown Location" : address
    }
    
    var displayName: String {
        guard !name.isEmpty else {
            return "New Place"
        }
        return name
    }
    
    var hasValidSocialURL: Bool {
        guard !socialURL.isEmpty else { return false }
        return socialURL.isValidURL
    }
    
    init(
        name: String,
        address: String,
        socialURL: String,
        rating: Double = 0.0,
        photoURL: String? = nil,
        phoneNumber: String? = nil,
        website: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.socialURL = socialURL
        self.rating = rating
        self.addedDate = Date()
        self.photoURL = photoURL
        self.phoneNumber = phoneNumber
        self.website = website
    }
}

// No extensions needed - using shared ones from main target