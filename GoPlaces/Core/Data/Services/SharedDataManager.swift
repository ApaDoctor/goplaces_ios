//
//  SharedDataManager.swift
//  GoPlaces
//
//  Shared SwiftData container for main app and Share Extension
//  Uses App Group for data sharing between targets
//  Created by Volodymyr Piskun on 04.09.2025.
//

import SwiftData
import Foundation
import os.log

@MainActor
class SharedDataManager: ObservableObject {
    static let shared = SharedDataManager()
    
    private let container: ModelContainer
    private let context: ModelContext
    private let logger = Logger(subsystem: "com.goplaces.SharedDataManager", category: "DataPersistence")
    
    private init() {
        do {
            let schema = Schema([Place.self])
            
            // Use default container for development (App Group requires Apple Developer setup)
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            container = try ModelContainer(for: schema, configurations: [configuration])
            context = container.mainContext
            
            logger.info("SharedDataManager initialized successfully with default container")
            logger.info("Note: App Group sharing requires Apple Developer Console configuration")
            
        } catch {
            logger.error("Failed to initialize SharedDataManager: \(error.localizedDescription)")
            #if DEBUG
            // Development fallback: remove existing store and retry to recover from migration issues
            do {
                let fileManager = FileManager.default
                let appSupport = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let defaultStoreURL = appSupport.appendingPathComponent("default.store")
                if fileManager.fileExists(atPath: defaultStoreURL.path) {
                    try fileManager.removeItem(at: defaultStoreURL)
                    logger.warning("Deleted corrupted SwiftData store at \(defaultStoreURL.path). Retrying initialization.")
                }
                let schema = Schema([Place.self])
                let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                container = try ModelContainer(for: schema, configurations: [configuration])
                context = container.mainContext
                logger.info("SharedDataManager recovered by resetting the local store (DEBUG only)")
            } catch {
                fatalError("Failed to recover SharedDataManager after store reset: \(error)")
            }
            #else
            fatalError("Failed to initialize SharedDataManager: \(error)")
            #endif
        }
    }
    
    // MARK: - Place Management
    
    /// Save places to shared container with duplicate detection
    func savePlaces(_ places: [Place]) throws {
        logger.info("Attempting to save \(places.count) places")
        
        var savedCount = 0
        var duplicatesFound = 0
        
        for place in places {
            // Check for duplicates based on social URL
            let existingPlace = try fetchPlace(by: place.socialURL)
            if existingPlace == nil {
                context.insert(place)
                savedCount += 1
                logger.debug("Inserted place: \(place.name)")
            } else {
                duplicatesFound += 1
                logger.debug("Duplicate found for place: \(place.name) with URL: \(place.socialURL)")
            }
        }
        
        if savedCount > 0 {
            try context.save()
            logger.info("Successfully saved \(savedCount) places, skipped \(duplicatesFound) duplicates")
        } else {
            logger.info("No new places to save, \(duplicatesFound) duplicates found")
        }
    }
    
    /// Fetch all places sorted by date added
    func fetchAllPlaces() throws -> [Place] {
        let descriptor = FetchDescriptor<Place>(
            sortBy: [SortDescriptor(\.addedDate, order: .reverse)]
        )
        let places = try context.fetch(descriptor)
        logger.debug("Fetched \(places.count) places")
        return places
    }
    
    /// Fetch place by social URL for duplicate detection
    func fetchPlace(by socialURL: String) throws -> Place? {
        let predicate = #Predicate<Place> { place in
            place.socialURL == socialURL
        }
        let descriptor = FetchDescriptor<Place>(predicate: predicate)
        let places = try context.fetch(descriptor)
        return places.first
    }
    
    /// Delete a place
    func deletePlace(_ place: Place) throws {
        context.delete(place)
        try context.save()
        logger.info("Deleted place: \(place.name)")
    }
    
    /// Search places by name or address
    func searchPlaces(query: String) throws -> [Place] {
        guard !query.isEmpty else {
            return try fetchAllPlaces()
        }
        
        let predicate = #Predicate<Place> { place in
            place.name.localizedStandardContains(query) ||
            place.address.localizedStandardContains(query)
        }
        let descriptor = FetchDescriptor<Place>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.addedDate, order: .reverse)]
        )
        let places = try context.fetch(descriptor)
        logger.debug("Search for '\(query)' returned \(places.count) places")
        return places
    }
    
    // MARK: - Extension Helper Methods
    
    /// Save places from Share Extension with detailed result callback
    func savePlacesFromExtraction(_ places: [Place], completion: @escaping (Result<ShareExtensionSaveResult, Error>) -> Void) {
        Task {
            do {
                let initialCount = try fetchAllPlaces().count
                try savePlaces(places)
                let finalCount = try fetchAllPlaces().count
                let newPlacesCount = finalCount - initialCount
                let duplicatesCount = places.count - newPlacesCount
                
                let result = ShareExtensionSaveResult(
                    totalSubmitted: places.count,
                    newPlacesSaved: newPlacesCount,
                    duplicatesFound: duplicatesCount,
                    success: true
                )
                
                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                logger.error("Failed to save places from extraction: \(error.localizedDescription)")
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Real-time Synchronization
    
    /// Get the model context for SwiftUI Query usage
    var modelContext: ModelContext {
        return context
    }
    
    /// Get the model container for SwiftUI modelContainer modifier
    var modelContainer: ModelContainer {
        return container
    }
}

// MARK: - Share Extension Save Result

struct ShareExtensionSaveResult {
    let totalSubmitted: Int
    let newPlacesSaved: Int
    let duplicatesFound: Int
    let success: Bool
    
    var hasNewPlaces: Bool {
        return newPlacesSaved > 0
    }
    
    var hasDuplicates: Bool {
        return duplicatesFound > 0
    }
    
    var displayMessage: String {
        if !success {
            return "Failed to save places"
        }
        
        if newPlacesSaved == 0 {
            if duplicatesFound > 0 {
                return "All \(duplicatesFound) place(s) already in your collection"
            }
            return "No places were saved"
        }
        
        if duplicatesFound == 0 {
            return "Added \(newPlacesSaved) place(s) to your collection"
        }
        
        return "Added \(newPlacesSaved) new place(s), \(duplicatesFound) already saved"
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let sharedDataDidChange = Notification.Name("sharedDataDidChange")
    static let placesDidUpdate = Notification.Name("placesDidUpdate")
}