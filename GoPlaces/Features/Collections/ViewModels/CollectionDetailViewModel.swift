//
//  CollectionDetailViewModel.swift
//  GoPlaces
//
//  ViewModel for CollectionDetailView to handle API integration
//

import Foundation
import SwiftUI
import Combine
import OSLog

private extension Notification.Name {
    static let collectionCoverUpdated = Notification.Name("CollectionCoverUpdated")
}

@MainActor
class CollectionDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var places: [Place] = []
    @Published var shareLink: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var presentedPlace: PresentedPlace? = nil
    @Published var coverImageUrl: String? = nil
    @Published var successMessage: String? = nil
    @Published var showSuccess: Bool = false
    @Published var didDeleteCollection: Bool = false
    
    // MARK: - Private Properties
    private let apiClient: APIClient
    private let logger = Logger(subsystem: "com.goplaces.app", category: "CollectionDetailViewModel")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        self.apiClient = APIClient()
    }
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public Methods
    
    /// Fetch collection details including places and share link from API
    func fetchCollectionDetails(collectionId: String) async {
        logger.info("Fetching collection details for: \(collectionId)")
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.showError = false
        }
        
        do {
            let collectionResponse = try await apiClient.getCollectionPlaces(collectionId: collectionId)
            self.lastAPIPlaces = collectionResponse.places
            
            // Update UI on main thread
            await MainActor.run {
                // Convert API places to our Place model
                self.places = collectionResponse.places.map { $0.toPlace() }
                
                self.shareLink = collectionResponse.shareLink
                self.coverImageUrl = collectionResponse.collection.coverImageUrl
                self.isLoading = false
            }
            
            logger.info("Successfully fetched \(self.places.count) places for collection")
            
        } catch {
            logger.error("Failed to fetch collection details: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = "Failed to load collection: \(error.localizedDescription)"
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Navigation
    func presentPlace(_ place: Place) {
        // Prefer index-based mapping to preserve order between API places and UI places
        if let idx = places.firstIndex(where: { $0.id == place.id }), idx < lastAPIPlaces.count {
            let api = lastAPIPlaces[idx]
            presentedPlace = PresentedPlace(remoteId: api.id, displayName: place.displayName)
            return
        }
        // Fallback to name/address match
        if let api = lastAPIPlaces.first(where: { $0.name == place.name && $0.address == place.address }) {
            presentedPlace = PresentedPlace(remoteId: api.id, displayName: place.displayName)
            return
        }
        // Final fallback: synthesize an id so detail view still opens (mock backend supports fallback details)
        presentedPlace = PresentedPlace(remoteId: "synthetic-\(place.id.uuidString)", displayName: place.displayName)
    }
    
    // Keep last API objects to allow id mapping
    private var lastAPIPlaces: [APIPlace] = []
    
    /// Generate share content with the collection link
    func generateShareContent(collectionName: String, collectionDescription: String?) -> String {
        var shareText = "📍 \(collectionName) Collection\n"
        
        if let description = collectionDescription {
            shareText += "\(description)\n\n"
        }
        
        shareText += "📍 \(places.count) amazing places\n\n"
        
        // Add first few places
        for place in places.prefix(3) {
            shareText += "• \(place.displayName)\n"
        }
        
        if places.count > 3 {
            shareText += "• ... and \(places.count - 3) more\n"
        }
        
        // Add the share link
        if !shareLink.isEmpty {
            shareText += "\n🔗 \(shareLink)\n"
        }
        
        shareText += "\nShared via GoPlaces 📍"
        
        return shareText
    }
    
    // MARK: - Private Methods
    
    // Removed mock fallback; production uses API only

    // MARK: - Add Place Flow
    func addPlace(collectionId: String, name: String, address: String, socialURL: String?, imageData: Data?) async {
        await MainActor.run { self.isLoading = true }
        do {
            // 1) Create place
            let created = try await apiClient.createPlace(in: collectionId, name: name, address: address, socialURL: socialURL)
            // 2) Upload photo if provided
            if let data = imageData {
                _ = try await apiClient.uploadPlacePhoto(collectionId: collectionId, placeId: created.id, imageData: data, filename: "photo.jpg")
            }
            // 3) Refresh list
            let response = try await apiClient.getCollectionPlaces(collectionId: collectionId)
            self.lastAPIPlaces = response.places
            await MainActor.run {
                self.places = response.places.map { $0.toPlace() }
                self.shareLink = response.shareLink
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to add place: \(error.localizedDescription)"
                self.showError = true
                self.isLoading = false
            }
        }
    }

    // MARK: - Edit Collection
    func updateCollection(collectionId: String, name: String?, description: String?, coverImageUrl: String?, colorTheme: String?, isFavorite: Bool?, tags: [String]?) async {
        do {
            let request = UpdateCollectionRequest(
                name: name,
                description: description,
                coverImageUrl: coverImageUrl,
                colorTheme: colorTheme,
                isFavorite: isFavorite,
                tags: tags
            )
            let updated = try await apiClient.updateCollection(collectionId, request: request)
            CollectionEventBus.shared.events.send(.updated(updated))
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update collection: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }

    // MARK: - Cover Upload
    func uploadCollectionCover(collectionId: String, imageData: Data) async {
        await MainActor.run { self.isLoading = true }
        do {
            let newUrl = try await apiClient.uploadCollectionCover(collectionId: collectionId, imageData: imageData)
            // Cache-busting query to avoid AsyncImage showing stale image
            let cacheBusted = newUrl + "?t=\(Int(Date().timeIntervalSince1970))"
            // Optionally refresh places/collection metadata
            let response = try? await apiClient.getCollectionPlaces(collectionId: collectionId)
            if let response {
                self.lastAPIPlaces = response.places
                await MainActor.run {
                    self.places = response.places.map { $0.toPlace() }
                    self.shareLink = response.shareLink
                }
                CollectionEventBus.shared.events.send(.updated(response.collection))
            }
            await MainActor.run {
                self.coverImageUrl = cacheBusted
                self.isLoading = false
                self.successMessage = "Cover updated successfully"
                self.showSuccess = true
            }
            CollectionEventBus.shared.events.send(.coverUpdated(collectionId: collectionId, coverURL: cacheBusted))
            // Notify collections view to update its card
            NotificationCenter.default.post(
                name: .collectionCoverUpdated,
                object: nil,
                userInfo: [
                    "collectionId": collectionId,
                    "coverImageUrl": cacheBusted
                ]
            )
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to upload cover: \(error.localizedDescription)"
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Delete Collection
    func deleteCollection(collectionId: String) async -> Bool {
        await MainActor.run {
            self.errorMessage = nil
            self.showError = false
            self.didDeleteCollection = false
        }
        do {
            try await apiClient.deleteCollection(collectionId)
            await MainActor.run {
                self.successMessage = "Collection deleted successfully"
                self.showSuccess = true
                self.didDeleteCollection = true
            }
            CollectionEventBus.shared.events.send(.deleted(collectionId))
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete collection: \(error.localizedDescription)"
                self.showError = true
                self.didDeleteCollection = false
            }
            return false
        }
    }
}

struct PresentedPlace: Identifiable {
    let remoteId: String
    let displayName: String
    var id: String { remoteId }
}