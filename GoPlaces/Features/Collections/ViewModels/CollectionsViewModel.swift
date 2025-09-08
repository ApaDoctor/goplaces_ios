//
//  CollectionsViewModel.swift
//  GoPlaces
//
//  View model for managing collections with API integration
//  Created by Volodymyr Piskun on 06.09.2025.
//

import SwiftUI
import Combine

@MainActor
class CollectionsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var collections: [PlaceCollection] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var scrollOffset: CGFloat = 0
    @Published var selectedCollections: Set<String> = []
    @Published var isSelectionMode = false
    @Published var searchQuery = ""
    @Published var showCreateSheet = false
    
    // MARK: - Private Properties
    
    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredCollections: [PlaceCollection] {
        if searchQuery.isEmpty {
            return collections
        }
        return collections.filter { collection in
            collection.name.localizedCaseInsensitiveContains(searchQuery) ||
            (collection.description?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
            collection.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    var hasCollections: Bool {
        !collections.isEmpty
    }
    
    var selectedCount: Int {
        selectedCollections.count
    }
    
    // MARK: - Initialization
    
    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient()
        setupBindings()
        subscribeToCollectionEvents()
        NotificationCenter.default.addObserver(forName: Notification.Name("CollectionCoverUpdated"), object: nil, queue: .main) { [weak self] note in
            guard let self = self else { return }
            guard let userInfo = note.userInfo as? [String: Any],
                  let collectionId = userInfo["collectionId"] as? String,
                  let url = userInfo["coverImageUrl"] as? String else { return }
            if let idx = self.collections.firstIndex(where: { $0.id == collectionId }) {
                var updated = self.collections[idx]
                // Inject cache-busted URL into model by recreating struct
                self.collections[idx] = PlaceCollection(
                    id: updated.id,
                    name: updated.name,
                    description: updated.description,
                    coverImageUrl: url,
                    placeCount: updated.placeCount,
                    createdAt: updated.createdAt,
                    updatedAt: Date(),
                    colorTheme: updated.colorTheme,
                    isFavorite: updated.isFavorite,
                    tags: updated.tags
                )
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Auto-exit selection mode when all items deselected
        $selectedCollections
            .sink { [weak self] selected in
                if selected.isEmpty && self?.isSelectionMode == true {
                    self?.isSelectionMode = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func subscribeToCollectionEvents() {
        CollectionEventBus.shared.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .updated(let updated):
                    if let idx = self.collections.firstIndex(where: { $0.id == updated.id }) {
                        self.collections[idx] = updated
                    }
                case .deleted(let id):
                    withAnimation(.easeOut(duration: 0.25)) {
                        self.collections.removeAll { $0.id == id }
                        self.selectedCollections.remove(id)
                    }
                case .coverUpdated(let collectionId, let coverURL):
                    if let idx = self.collections.firstIndex(where: { $0.id == collectionId }) {
                        let c = self.collections[idx]
                        self.collections[idx] = PlaceCollection(
                            id: c.id,
                            name: c.name,
                            description: c.description,
                            coverImageUrl: coverURL,
                            placeCount: c.placeCount,
                            createdAt: c.createdAt,
                            updatedAt: Date(),
                            colorTheme: c.colorTheme,
                            isFavorite: c.isFavorite,
                            tags: c.tags
                        )
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load all collections from the API
    func loadCollections() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let fetchedCollections = try await apiClient.getAllCollections()
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.collections = fetchedCollections.sorted { 
                        $0.updatedAt > $1.updatedAt 
                    }
                }
                self.isLoading = false
            }
        } catch {
            // Ignore benign cancellation errors (common during pull-to-refresh / view changes)
            if error is CancellationError {
                await MainActor.run { self.isLoading = false }
                return
            }
            if let urlError = error as? URLError, urlError.code == .cancelled {
                await MainActor.run { self.isLoading = false }
                return
            }
            await MainActor.run {
                self.error = error
                self.isLoading = false
                print("Failed to load collections: \(error)")
            }
        }
    }
    
    /// Refresh collections with pull-to-refresh
    func refreshCollections() async {
        // Don't set isLoading for refresh to avoid showing spinner
        error = nil
        
        do {
            let fetchedCollections = try await apiClient.getAllCollections()
            
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.collections = fetchedCollections.sorted { 
                        $0.updatedAt > $1.updatedAt 
                    }
                }
                
                // Haptic feedback for successful refresh
                HapticManager.shared.trigger(.pullToRefresh)
            }
        } catch {
            // Swallow cancellation errors to prevent noisy "cancelled" alerts
            if error is CancellationError { return }
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
            await MainActor.run {
                self.error = error
                HapticManager.shared.trigger(.error)
            }
        }
    }
    
    /// Create a new collection
    func createCollection(name: String, description: String? = nil) async {
        guard !name.isEmpty else { return }
        
        do {
            let newCollection = try await apiClient.createCollection(
                name: name,
                description: description,
                coverImageUrl: nil,
                colorTheme: Color.randomThemeColor(),
                tags: []
            )
            
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.collections.insert(newCollection, at: 0)
                }
                self.showCreateSheet = false
                HapticManager.shared.trigger(.success)
            }
        } catch {
            await MainActor.run {
                self.error = error
                HapticManager.shared.trigger(.error)
            }
        }
    }
    
    /// Delete a collection
    func deleteCollection(_ collection: PlaceCollection) async {
        do {
            try await apiClient.deleteCollection(collection.id)
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.collections.removeAll { $0.id == collection.id }
                    self.selectedCollections.remove(collection.id)
                }
                HapticManager.shared.trigger(.delete)
            }
        } catch {
            await MainActor.run {
                self.error = error
                HapticManager.shared.trigger(.error)
            }
        }
    }
    
    /// Delete multiple collections
    func deleteSelectedCollections() async {
        let toDelete = Array(selectedCollections)
        
        for collectionId in toDelete {
            if let collection = collections.first(where: { $0.id == collectionId }) {
                await deleteCollection(collection)
            }
        }
        
        isSelectionMode = false
        selectedCollections.removeAll()
    }
    
    /// Toggle favorite status
    func toggleFavorite(_ collection: PlaceCollection) async {
        let request = UpdateCollectionRequest(
            name: nil,
            description: nil,
            coverImageUrl: nil,
            colorTheme: nil,
            isFavorite: !collection.isFavorite,
            tags: nil
        )
        
        do {
            let updated = try await apiClient.updateCollection(collection.id, request: request)
            
            await MainActor.run {
                if let index = self.collections.firstIndex(where: { $0.id == collection.id }) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.collections[index] = updated
                    }
                }
                HapticManager.shared.trigger(.favorite)
            }
        } catch {
            await MainActor.run {
                self.error = error
                HapticManager.shared.trigger(.error)
            }
        }
    }
    
    // MARK: - Selection Management
    
    func toggleSelection(for collection: PlaceCollection) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedCollections.contains(collection.id) {
                selectedCollections.remove(collection.id)
            } else {
                selectedCollections.insert(collection.id)
            }
        }
        HapticManager.shared.trigger(.selection)
    }
    
    func selectAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedCollections = Set(collections.map { $0.id })
        }
        HapticManager.shared.trigger(.selection)
    }
    
    func deselectAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedCollections.removeAll()
            isSelectionMode = false
        }
        HapticManager.shared.trigger(.selection)
    }
    
    func enterSelectionMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSelectionMode = true
        }
        HapticManager.shared.trigger(.longPress)
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        error = nil
    }
    
    var errorMessage: String? {
        guard let error = error else { return nil }
        
        if let apiError = error as? APIError {
            return apiError.message
        }
        
        return error.localizedDescription
    }
}