//
//  MyPlacesViewModel.swift
//  GoPlaces
//
//  Created by Volodymyr Piskun on 03.09.2025.
//

import Foundation
import SwiftData
import os.log

@MainActor
final class MyPlacesViewModel: ObservableObject {
    
    // MARK: - Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private var placeService: SwiftDataPlaceService?
    private let logger = Logger(subsystem: "com.goplaces.app", category: "MyPlacesViewModel")
    
    // MARK: - Initialization
    init() {
        logger.info("MyPlacesViewModel initialized")
    }
    
    // Set up the place service with model context
    func configure(with modelContext: ModelContext) {
        self.placeService = SwiftDataPlaceService(modelContext: modelContext)
        logger.info("MyPlacesViewModel configured with SwiftData")
    }
    
    // MARK: - Actions
    func deletePlace(_ place: Place) async {
        guard let placeService = placeService else {
            logger.error("PlaceService not configured")
            return
        }
        
        isLoading = true
        
        do {
            try await placeService.deletePlace(place)
            logger.info("Successfully deleted place: \(place.displayName)")
        } catch {
            logger.error("Failed to delete place: \(error.localizedDescription)")
            ErrorHandler.shared.handle(error, severity: .medium)
        }
        
        isLoading = false
    }
    
    func deleteAllPlaces() async {
        isLoading = true
        
        do {
            try await placeService?.deleteAllPlaces()
            logger.warning("Successfully deleted all places")
        } catch {
            logger.error("Failed to delete all places: \(error.localizedDescription)")
            ErrorHandler.shared.handle(error, severity: .high)
        }
        
        isLoading = false
    }
    
    // MARK: - Error Handling
    /// @deprecated Use ErrorHandler.shared.handle() instead
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}