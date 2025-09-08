//
//  CollectionsView.swift
//  GoPlaces
//
//  Main collections screen with asymmetric grid layout
//  Created by Volodymyr Piskun on 06.09.2025.
//

import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel = CollectionsViewModel()
    @State private var showCreateSheet = false
    @State private var selectedCollection: PlaceCollection?
    @State private var showingCollectionDetail = false
    @State private var refreshID = UUID()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.adaptiveCardBackground
                    .ignoresSafeArea()
                
                if viewModel.hasCollections || viewModel.isLoading {
                    // Main content with collections
                    ScrollView {
                        VStack(spacing: 0) {
                            // Pull to refresh implementation
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geometry.frame(in: .global).minY
                                    )
                            }
                            .frame(height: 0)
                            
                            // Collections Grid
                            CollectionsGridView(
                                collections: viewModel.filteredCollections,
                                selectedCollections: $viewModel.selectedCollections,
                                isSelectionMode: $viewModel.isSelectionMode,
                                onCollectionTap: handleCollectionTap,
                                onCollectionLongPress: { collection in
                                    viewModel.enterSelectionMode()
                                    viewModel.toggleSelection(for: collection)
                                },
                                onCreateNew: {
                                    showCreateSheet = true
                                }
                            )
                            .padding(.top, DesignSystem.Spacing.lg)
                            .padding(.bottom, 100) // Space for tab bar
                        }
                        .padding(.horizontal, DesignSystem.Spacing.screenMargin) // Container-level padding
                    }
                    .refreshable {
                        await viewModel.refreshCollections()
                    }
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        viewModel.scrollOffset = value
                    }
                } else {
                    // Empty state
                    EmptyCollectionsView(onCreateTap: {
                        showCreateSheet = true
                    })
                }
                
                // Loading overlay
                if viewModel.isLoading && !viewModel.hasCollections {
                    LoadingOverlay()
                }
            }
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .searchable(text: $viewModel.searchQuery, prompt: "Search collections")
            .sheet(isPresented: $showCreateSheet) {
                CreateCollectionSheet(viewModel: viewModel)
            }
            .sheet(item: $selectedCollection) { collection in
                CollectionDetailView(collection: collection)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            // Auto-refresh when app returns to foreground or deep link selects Collections
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task { await viewModel.refreshCollections() }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CollectionCoverUpdated"))) { _ in
                Task { await viewModel.refreshCollections() }
            }
        }
        .task {
            await viewModel.loadCollections()
        }
        // Collection updates/deletes are now handled by CollectionsViewModel via CollectionEventBus
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.isSelectionMode {
                Button("Done") {
                    viewModel.deselectAll()
                }
                .font(DesignSystem.Typography.headline)
            } else {
                // Hidden add button (kept for future use)
                Button { } label: {
                    Image(systemName: DesignSystem.Icons.add)
                        .font(.system(size: 22, weight: .medium))
                        .opacity(0)
                }
                .disabled(true)
            }
        }
        
        if viewModel.isSelectionMode {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Select All") {
                    viewModel.selectAll()
                }
                .font(DesignSystem.Typography.headline)
            }
        }
        
        if viewModel.isSelectionMode && !viewModel.selectedCollections.isEmpty {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteSelectedCollections()
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Spacer()
                    
                    Text("\(viewModel.selectedCount) selected")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleCollectionTap(_ collection: PlaceCollection) {
        if viewModel.isSelectionMode {
            viewModel.toggleSelection(for: collection)
        } else {
            // Navigate to collection detail
            selectedCollection = collection
        }
    }
}

// MARK: - Collections Grid View

struct CollectionsGridView: View {
    let collections: [PlaceCollection]
    @Binding var selectedCollections: Set<String>
    @Binding var isSelectionMode: Bool
    let onCollectionTap: (PlaceCollection) -> Void
    let onCollectionLongPress: (PlaceCollection) -> Void
    let onCreateNew: () -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
        GridItem(.flexible(), spacing: 0)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: DesignSystem.Spacing.md) {
            ForEach(collections) { collection in
                GridCollectionCard(
                    collection: collection,
                    isSelected: selectedCollections.contains(collection.id),
                    onTap: { onCollectionTap(collection) }
                )
                .onLongPressGesture {
                    onCollectionLongPress(collection)
                }
            }
            
            // Add new collection card
            NewCollectionCard(onTap: onCreateNew)
        }
    }
}

// MARK: - Empty State View

struct EmptyCollectionsView: View {
    let onCreateTap: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            
            // Icon
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 80))
                .foregroundColor(DesignSystem.Colors.coralHeart.opacity(0.5))
            
            // Title
            Text("No Collections Yet")
                .font(DesignSystem.Typography.title)
                .foregroundColor(Color.adaptivePrimaryText)
            
            // Description
            Text("Create your first collection to organize your favorite places")
                .font(DesignSystem.Typography.body)
                .foregroundColor(Color.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // CTA Button
            Button(action: onCreateTap) {
                HStack {
                    Image(systemName: DesignSystem.Icons.add)
                    Text("Create Collection")
                }
                .font(DesignSystem.Typography.headline)
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.coralHeart)
                .cornerRadius(DesignSystem.Radii.button)
            }
            .pressAnimation()
            .padding(.top, DesignSystem.Spacing.md)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    @State private var funnyMessage = "Loading your collections..."
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(DesignSystem.Colors.oceanTeal)
            
            Text(funnyMessage)
                .font(DesignSystem.Typography.body)
                .foregroundColor(Color.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .task {
            // Fetch funny message from API
            let apiClient = APIClient()
            if let message = try? await apiClient.getFunnyMessage(category: .processing) {
                funnyMessage = message.message
            }
        }
    }
}

// MARK: - Create Collection Sheet

struct CreateCollectionSheet: View {
    @ObservedObject var viewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                        .font(DesignSystem.Typography.body)
                        .focused($isNameFocused)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .font(DesignSystem.Typography.body)
                        .lineLimit(3...6)
                }
                
                Section {
                    Text("You can customize the cover image and theme color later")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await viewModel.createCollection(
                                name: name,
                                description: description.isEmpty ? nil : description
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                    .font(DesignSystem.Typography.headline)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            isNameFocused = true
        }
    }
}

// MARK: - Preview

#Preview {
    CollectionsView()
}