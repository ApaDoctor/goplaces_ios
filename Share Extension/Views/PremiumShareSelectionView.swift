//
//  PremiumShareSelectionView.swift
//  Share Extension
//
//  New premium place and collection selection view for Share Extension
//  Created by Assistant on 2025-09-06.
//

import SwiftUI

struct PremiumShareSelectionView: View {
    let taskId: String
    let onSave: ([String], [String]) -> Void // (selectedPlaceIds, selectedCollectionIds)
    let onCancel: () -> Void
    
    @StateObject private var apiClient = APIClient()
    
    // Places data
    @State private var places: [PlaceWithSelection] = []
    @State private var selectedPlaceIds: Set<String> = []
    
    // Collections data
    @State private var collections: [PlaceCollection] = []
    @State private var selectedCollectionIds: Set<String> = []
    
    // UI State
    @State private var currentStep: SelectionStep = .selectingPlaces
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCreateCollection = false
    @State private var showSuccess = false
    
    enum SelectionStep {
        case selectingPlaces
        case selectingCollections
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.warmWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Progress indicator
                progressIndicator
                
                // Content
                Group {
                    switch currentStep {
                    case .selectingPlaces:
                        placeSelectionContent
                    case .selectingCollections:
                        collectionSelectionContent
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
        // Pin the action bar to the bottom and adjust scrollable content insets automatically
        .safeAreaInset(edge: .bottom) { bottomActions }
        .task {
            await loadData()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showCreateCollection) {
            ShareCreateCollectionSheet { name, description in
                await createCollection(name: name, description: description)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Save to GoPlaces")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.deepNavy)
                
                Text(headerSubtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.gray.opacity(0.4))
                    .background(Circle().fill(Color.white))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    private var headerSubtitle: String {
        switch currentStep {
        case .selectingPlaces:
            return "\(places.count) places found • \(selectedPlaceIds.count) selected"
        case .selectingCollections:
            return "Choose collections for your places"
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ProgressStep(
                number: 1,
                title: "Places",
                isActive: currentStep == .selectingPlaces,
                isCompleted: currentStep != .selectingPlaces
            )
            
            Rectangle()
                .fill(currentStep == .selectingPlaces ? Color.gray.opacity(0.3) : Color.oceanTeal)
                .frame(height: 2)
            
            ProgressStep(
                number: 2,
                title: "Collections",
                isActive: currentStep == .selectingCollections,
                isCompleted: false
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.warmWhite)
    }
    
    // MARK: - Place Selection
    
    private var placeSelectionContent: some View {
        VStack(spacing: 0) {
            // Quick actions
            HStack(spacing: 12) {
                Button {
                    selectedPlaceIds = Set(places.map { $0.id })
                } label: {
                    Text("Select All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.oceanTeal)
                }
                
                Button {
                    selectedPlaceIds.removeAll()
                } label: {
                    Text("Clear")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Places list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(places) { place in
                        SharePlaceSelectionRow(
                            place: place,
                            isSelected: selectedPlaceIds.contains(place.id)
                        ) {
                            togglePlaceSelection(place.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Collection Selection
    
    private var collectionSelectionContent: some View {
        VStack(spacing: 0) {
            // Create new button
            Button {
                showCreateCollection = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.oceanTeal)
                    
                    Text("Create New Collection")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.deepNavy)
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                                )
                                .foregroundColor(Color.oceanTeal.opacity(0.5))
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Collections grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(collections) { collection in
                        ShareCollectionSelectionCard(
                            collection: collection,
                            isSelected: selectedCollectionIds.contains(collection.id)
                        ) {
                            toggleCollectionSelection(collection.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Success View
    
    private var successContent: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success icon - coral with teal accent ring
            ZStack {
                Circle()
                    .fill(Color.oceanTeal.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.coralHeart)
            }
            .scaleEffect(showSuccess ? 1.0 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: showSuccess)
            
            VStack(spacing: 12) {
                Text("Success!")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color.deepNavy)
                
                Text("Successfully added \(selectedPlaceIds.count) place\(selectedPlaceIds.count == 1 ? "" : "s") to \(selectedCollectionIds.count) collection\(selectedCollectionIds.count == 1 ? "" : "s")")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showSuccess ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.3).delay(0.2), value: showSuccess)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button {
                    // This button is never shown because we don't use internal success state
                    // The parent view handles success
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Open GoPlaces")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.coralHeart)
                    .cornerRadius(12)
                }
                
                Button {
                    // This button is never shown because we don't use internal success state
                    // The parent view handles success
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.oceanTeal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.oceanTeal.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.oceanTeal, lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            showSuccess = true
            // Don't auto-dismiss - let user decide
            // They can tap Done or Open App
        }
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                if currentStep == .selectingCollections {
                    Button {
                        withAnimation {
                            currentStep = .selectingPlaces
                        }
                    } label: {
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                }
                
                Button {
                    handlePrimaryAction()
                } label: {
                    Text(primaryActionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(primaryActionDisabled ? Color.gray : Color.coralHeart)
                        )
                }
                .disabled(primaryActionDisabled)
                .animation(.easeInOut(duration: 0.2), value: primaryActionDisabled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }
    
    private var primaryActionTitle: String {
        switch currentStep {
        case .selectingPlaces:
            return "Continue"
        case .selectingCollections:
            return "Save"
        }
    }
    
    private var primaryActionDisabled: Bool {
        switch currentStep {
        case .selectingPlaces:
            return selectedPlaceIds.isEmpty
        case .selectingCollections:
            return selectedCollectionIds.isEmpty
        }
    }
    
    private func handlePrimaryAction() {
        switch currentStep {
        case .selectingPlaces:
            withAnimation {
                currentStep = .selectingCollections
            }
            if collections.isEmpty {
                Task {
                    await loadCollections()
                }
            }
        case .selectingCollections:
            // Call the save callback with selected items
            onSave(Array(selectedPlaceIds), Array(selectedCollectionIds))
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        isLoading = true
        
        // Load places via dedicated selection endpoint
        do {
            let selection = try await apiClient.getTaskPlacesForSelection(taskId)
            await MainActor.run {
                self.places = selection
                // Respect backend-provided selection state
                self.selectedPlaceIds = Set(self.places.filter { $0.isSelected ?? false }.map { $0.id })
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load places: \(error.localizedDescription)"
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    private func loadCollections() async {
        do {
            let loadedCollections = try await apiClient.getAllCollections()
            
            await MainActor.run {
                self.collections = loadedCollections
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load collections"
                self.showError = true
            }
        }
    }
    
    private func createCollection(name: String, description: String?) async {
        do {
            let newCollection = try await apiClient.createCollection(
                name: name,
                description: description,
                coverImageUrl: nil,
                colorTheme: "coral", // Default theme, can be customized later
                tags: []
            )
            
            await MainActor.run {
                self.collections.insert(newCollection, at: 0)
                self.selectedCollectionIds.insert(newCollection.id)
                self.showCreateCollection = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create collection"
                self.showError = true
            }
        }
    }
    
    // MARK: - Selection Helpers
    
    private func togglePlaceSelection(_ placeId: String) {
        if selectedPlaceIds.contains(placeId) {
            selectedPlaceIds.remove(placeId)
        } else {
            selectedPlaceIds.insert(placeId)
        }
    }
    
    private func toggleCollectionSelection(_ collectionId: String) {
        if selectedCollectionIds.contains(collectionId) {
            selectedCollectionIds.remove(collectionId)
        } else {
            selectedCollectionIds.insert(collectionId)
        }
    }
    
    private func iconForPlaceType(_ type: String?) -> String {
        switch type?.lowercased() {
        case "restaurant", "cafe":
            return "fork.knife"
        case "hotel", "lodging":
            return "bed.double.fill"
        case "museum":
            return "building.columns.fill"
        case "park":
            return "leaf.fill"
        case "shopping_mall":
            return "bag.fill"
        default:
            return "mappin.circle.fill"
        }
    }
}

// MARK: - Supporting Views

struct ProgressStep: View {
    let number: Int
    let title: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.coralHeart : (isCompleted ? Color.oceanTeal : Color.gray.opacity(0.3)))
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isActive ? .white : Color.gray)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(isActive ? Color.deepNavy : .secondary)
        }
    }
}

struct SharePlaceSelectionRow: View {
    let place: PlaceWithSelection
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        // Use explicit tap gesture to avoid toggling on scroll/drag
        HStack(spacing: 16) {
            // Leading visual: prefer image when provided by backend
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: place.categoryColor))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Group {
                            if let urlStr = place.imageUrl, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.black.opacity(0.05)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else if let symbol = place.sfSymbolName {
                                Image(systemName: symbol)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                    )
            }
            
            // Place info
            VStack(alignment: .leading, spacing: 4) {
                Text(place.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.deepNavy)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(place.displayAddress)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Render confidence indicator only if provided by backend
                    if let icon = place.confidenceIcon, !icon.isEmpty {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundColor(Color.successGreen)
                    }
                }
            }
            
            Spacer()
            
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(isSelected ? Color.oceanTeal : Color.gray.opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.oceanTeal : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareCollectionSelectionCard: View {
    let collection: PlaceCollection
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 0) {
                // Image
                AsyncImage(url: URL(string: collection.coverImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.themeGradient(for: collection.colorTheme ?? "coral"))
                }
                .frame(height: 100)
                .clipped()
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.deepNavy)
                        .lineLimit(1)
                    
                    Text("\(collection.placeCount) places")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.oceanTeal : Color.clear, lineWidth: 2)
            )
            .overlay(
                // Selection checkbox overlay positioned at top-right corner
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 26, height: 26)
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.coralHeart)
                                }
                            }
                            .padding(8)
                            Spacer()
                        }
                    }
                }
            )
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareCreateCollectionSheet: View {
    let onCreate: (String, String?) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                        .font(.system(size: 16))
                        .focused($isNameFocused)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .font(.system(size: 16))
                        .lineLimit(3...6)
                }
                
                Section {
                    Text("You can customize the cover image and theme color later")
                        .font(.system(size: 14))
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
                    .foregroundColor(Color.coralHeart)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await onCreate(name, description.isEmpty ? nil : description)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(name.isEmpty ? .regular : .medium)
                    .foregroundColor(name.isEmpty ? .gray : Color.coralHeart)
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

// Theme selection removed - can be customized later in main app

// MARK: - Color Extension Helper

extension Color {
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format: "#%06x", rgb)
    }
}

// MARK: - Preview

#Preview {
    PremiumShareSelectionView(
        taskId: "sample-task",
        onSave: { _, _ in },
        onCancel: { }
    )
}