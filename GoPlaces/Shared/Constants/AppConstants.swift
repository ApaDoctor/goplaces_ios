//
//  AppConstants.swift
//  GoPlaces
//
//  Created by Volodymyr Piskun on 03.09.2025.
//

import Foundation
import SwiftUI

// MARK: - App Constants
struct AppConstants {
    
    // MARK: - App Groups
    struct AppGroup {
        static let identifier = "group.com.goplaces.shared"
    }
    
    // MARK: - Core Data
    struct CoreData {
        static let containerName = "GoPlacesDataModel"
        static let storeName = "GoPlacesDataModel.sqlite"
    }
    
    // MARK: - UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 4
        static let defaultSpacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 24
        
        struct TabView {
            static let collectionsTitle = "Collections"
            // Icons chosen to match provided reference style while using SF Symbols
            static let planTitle = "Plan"
            static let planIcon = "map.fill"
            static let myTripsTitle = "My Trips"
            static let myTripsIcon = "location.north.circle.fill"
        }
        
        struct Animation {
            static let defaultDuration: TimeInterval = 0.3
            static let springResponse: Double = 0.5
            static let springDampingFraction: Double = 0.8
        }
    }
    
    // MARK: - Networking
    struct Network {
        static let timeoutInterval: TimeInterval = 30.0
        static let maxRetryAttempts = 3
    }
    
    // MARK: - Place Validation
    struct Place {
        struct Validation {
            static let nameMinLength = 1
            static let nameMaxLength = 200
            static let addressMaxLength = 500
            static let phoneNumberMaxLength = 20
            static let websiteMaxLength = 2048
        }
        
        struct Defaults {
            static let placeholderName = "Unnamed Place"
            static let unknownAddress = "Unknown Address"
        }
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let genericError = "An unexpected error occurred"
        static let networkError = "Network connection failed"
        static let coreDataError = "Failed to save data"
        static let invalidURL = "Invalid URL format"
        static let placeNotFound = "Place not found"
        static let validationFailed = "Validation failed"
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let placeDidSave = Notification.Name("placeDidSave")
    static let placeDidDelete = Notification.Name("placeDidDelete")
    static let coreDataContextDidSave = Notification.Name("coreDataContextDidSave")
    static let coreDataStackDidLoad = Notification.Name("coreDataStackDidLoad")
    static let coreDataStackFailure = Notification.Name("coreDataStackFailure")
}