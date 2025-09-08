//
//  Place.swift
//  GoPlaces
//
//  SwiftData Place Model - Migration from CoreData
//  Created by Volodymyr Piskun on 04.09.2025.
//

import SwiftData
import Foundation

@Model
class Place {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    // Provide default to support inferred SwiftData migration when older stores lack this field
    var socialURL: String = ""
    var addedDate: Date
    var rating: Double
    var photoURL: String?
    var phoneNumber: String?
    var website: String?
    
    // Computed properties for display
    var displayAddress: String {
        return address.isEmpty ? AppConstants.Place.Defaults.unknownAddress : address
    }
    
    var displayName: String {
        guard !name.isEmpty else {
            return AppConstants.Place.Defaults.placeholderName
        }
        return name
    }
    
    var hasValidCoordinates: Bool {
        // SwiftData doesn't have latitude/longitude in spec, but keeping logic for future
        return false
    }
    
    var formattedRating: String? {
        guard rating > 0 else { return nil }
        return String(format: "%.1f", rating)
    }
    
    var hasValidSocialURL: Bool {
        guard !socialURL.isEmpty else { return false }
        return socialURL.isValidURL
    }
    
    var socialURLObject: URL? {
        guard !socialURL.isEmpty else { return nil }
        return URL(string: socialURL)
    }
    
    var websiteURLObject: URL? {
        guard let website = website, !website.isEmpty else { return nil }
        return URL(string: website)
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

// MARK: - Validation
extension Place {
    
    /// Validate place data
    func validate() throws {
        // Validate name
        guard !name.isEmpty else {
            throw PlaceValidationError.nameRequired
        }
        
        guard name.count >= AppConstants.Place.Validation.nameMinLength &&
              name.count <= AppConstants.Place.Validation.nameMaxLength else {
            throw PlaceValidationError.nameInvalidLength
        }
        
        // Validate address if provided
        if !address.isEmpty {
            guard address.count <= AppConstants.Place.Validation.addressMaxLength else {
                throw PlaceValidationError.addressTooLong
            }
        }
        
        // Validate phone number if provided
        if let phone = phoneNumber, !phone.isEmpty {
            guard phone.count <= AppConstants.Place.Validation.phoneNumberMaxLength else {
                throw PlaceValidationError.phoneNumberTooLong
            }
        }
        
        // Validate website if provided
        if let website = website, !website.isEmpty {
            guard website.count <= AppConstants.Place.Validation.websiteMaxLength else {
                throw PlaceValidationError.websiteTooLong
            }
        }
        
        // Validate Social URL
        guard socialURL.isValidURL else {
            throw PlaceValidationError.invalidSocialURL
        }
        
        // Validate rating
        guard rating >= 0.0 && rating <= 5.0 else {
            throw PlaceValidationError.ratingOutOfRange
        }
    }
}

// MARK: - Place Validation Errors
enum PlaceValidationError: LocalizedError {
    case nameRequired
    case nameInvalidLength
    case addressTooLong
    case phoneNumberTooLong
    case websiteTooLong
    case invalidSocialURL
    case ratingOutOfRange
    
    var errorDescription: String? {
        switch self {
        case .nameRequired:
            return "Place name is required"
        case .nameInvalidLength:
            return "Place name must be between \(AppConstants.Place.Validation.nameMinLength) and \(AppConstants.Place.Validation.nameMaxLength) characters"
        case .addressTooLong:
            return "Address cannot exceed \(AppConstants.Place.Validation.addressMaxLength) characters"
        case .phoneNumberTooLong:
            return "Phone number cannot exceed \(AppConstants.Place.Validation.phoneNumberMaxLength) characters"
        case .websiteTooLong:
            return "Website URL cannot exceed \(AppConstants.Place.Validation.websiteMaxLength) characters"
        case .invalidSocialURL:
            return "Invalid social URL format"
        case .ratingOutOfRange:
            return "Rating must be between 0.0 and 5.0"
        }
    }
}