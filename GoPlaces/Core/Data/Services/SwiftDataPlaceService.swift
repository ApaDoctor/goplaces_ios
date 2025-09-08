//
//  SwiftDataPlaceService.swift
//  GoPlaces
//
//  SwiftData-based Place service to replace CoreData PlaceService
//  Created by Volodymyr Piskun on 04.09.2025.
//

import SwiftData
import Foundation

/// Service for managing Place entities using SwiftData
@MainActor
class SwiftDataPlaceService: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    @MainActor
    convenience init() {
        self.init(modelContext: SharedDataManager.shared.modelContext)
    }
    
    /// Create a new place
    func createPlace(
        name: String,
        address: String? = nil,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        sourceURL: String? = nil,
        rating: Double? = nil,
        phoneNumber: String? = nil,
        website: String? = nil
    ) async throws -> Place {
        
        // Clean the source URL if provided
        let cleanedURL = sourceURL?.cleanedURL ?? ""
        
        // Create new place with social URL as primary field
        let place = Place(
            name: name,
            address: address ?? "",
            socialURL: cleanedURL,
            rating: rating ?? 0.0,
            photoURL: nil,
            phoneNumber: phoneNumber,
            website: website
        )
        
        // Validate before saving
        try place.validate()
        
        // Insert and save
        modelContext.insert(place)
        
        do {
            try modelContext.save()
            return place
        } catch {
            // Remove from context if save failed
            modelContext.delete(place)
            throw PlaceServiceError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Fetch all places
    func fetchAllPlaces() throws -> [Place] {
        let descriptor = FetchDescriptor<Place>(
            sortBy: [SortDescriptor(\.addedDate, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw PlaceServiceError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Search places by name or address
    func searchPlaces(query: String) throws -> [Place] {
        let predicate = #Predicate<Place> { place in
            place.name.localizedStandardContains(query) ||
            place.address.localizedStandardContains(query)
        }
        
        let descriptor = FetchDescriptor<Place>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.addedDate, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw PlaceServiceError.searchFailed(error.localizedDescription)
        }
    }
    
    /// Update an existing place
    func updatePlace(_ place: Place) async throws {
        // Validate before saving
        try place.validate()
        
        do {
            try modelContext.save()
        } catch {
            throw PlaceServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Delete a place
    func deletePlace(_ place: Place) async throws {
        modelContext.delete(place)
        
        do {
            try modelContext.save()
        } catch {
            throw PlaceServiceError.deleteFailed(error.localizedDescription)
        }
    }
    
    /// Check if a place with the same social URL already exists
    func placeExists(socialURL: String) throws -> Bool {
        let cleanedURL = socialURL.cleanedURL
        
        let predicate = #Predicate<Place> { place in
            place.socialURL == cleanedURL
        }
        
        let descriptor = FetchDescriptor<Place>(
            predicate: predicate
        )
        
        do {
            let existingPlaces = try modelContext.fetch(descriptor)
            return !existingPlaces.isEmpty
        } catch {
            throw PlaceServiceError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Get place count
    func getPlaceCount() throws -> Int {
        let descriptor = FetchDescriptor<Place>()
        
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            throw PlaceServiceError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Delete all places
    func deleteAllPlaces() async throws {
        let descriptor = FetchDescriptor<Place>()
        
        do {
            let allPlaces = try modelContext.fetch(descriptor)
            for place in allPlaces {
                modelContext.delete(place)
            }
            try modelContext.save()
        } catch {
            throw PlaceServiceError.deleteFailed(error.localizedDescription)
        }
    }
}

// MARK: - Place Service Errors
enum PlaceServiceError: LocalizedError {
    case saveFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case searchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Failed to save place: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch places: \(message)"
        case .updateFailed(let message):
            return "Failed to update place: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete place: \(message)"
        case .searchFailed(let message):
            return "Failed to search places: \(message)"
        }
    }
}