//
//  PremiumPlaceSelectionView.swift
//  ShareExtension
//
//  Premium place selection view with enhanced UI and collection flow
//  Created by Volodymyr Piskun on 05.09.2025.
//

import SwiftUI

struct PremiumPlaceSelectionView: View {
    let taskId: String
    let onSave: ([String], [String]) -> Void // (selectedPlaceIds, selectedPlaceCollectionIds)
    let onCancel: () -> Void
    
    @StateObject private var apiClient = APIClient()
    @State private var places: [PlaceWithSelection] = []
    @State private var selectedPlaceIds: Set<String> = []
    @State private var collections: [PlaceCollection] = []
    @State private var selectedPlaceCollectionIds: Set<String> = []
    
    // Removed viewMode - share extension only uses list view
    @State private var currentStep: SelectionStep = .selectingPlaces
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showNewPlaceCollectionSheet = false
    @State private var showExpandedLocations = false
    @State private var showSuccessView = false
    
    // ViewMode removed for share extension - only list view supported
    
    enum SelectionStep {
        case selectingPlaces
        case selectingPlaceCollections
        case creatingPlaceCollection
    }
    
    private var stepIndicatorText: String {
        switch currentStep {
        case .selectingPlaces:
            return "Step 1 of 3 • Select Places"
        case .selectingPlaceCollections:
            return "Step 2 of 3 • Choose Collections"
        case .creatingPlaceCollection:
            return "Step 3 of 3 • New Collection"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium Navigation Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Save to GoPlaces")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.deepNavy)
                    
                    if !showSuccessView {
                        Text(stepIndicatorText)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color.coralHeart)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.warmWhite.opacity(0.98))
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // Main Content
            if showSuccessView {
                successView
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                switch currentStep {
                case .selectingPlaces:
                    placeSelectionView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .selectingPlaceCollections:
                    collectionSelectionView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .creatingPlaceCollection:
                    newPlaceCollectionView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentStep)
        .animation(.easeInOut(duration: 0.4), value: showSuccessView)
        .task {
            await loadPlaces()
        }
        .alert("Error", isPresented: $showError) {
            Button("Retry") {
                Task { await loadPlaces() }
            }
            Button("Cancel", role: .cancel) {
                onCancel()
            }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showNewPlaceCollectionSheet) {
            NewPlaceCollectionSheet(isPresented: $showNewPlaceCollectionSheet) { name, description, theme in
                Task {
                    do {
                        let collection = try await apiClient.createCollection(
                            name: name,
                            description: description,
                            coverImageUrl: nil,
                            colorTheme: theme,
                            tags: []
                        )
                        collections.append(collection)
                        selectedPlaceCollectionIds.insert(collection.id)
                    } catch {
                        errorMessage = "Failed to create collection: \(error.localizedDescription)"
                        showError = true
                    }
                }
            }
        }
    }
    
    // MARK: - Place Selection View
    
    @ViewBuilder
    private var placeSelectionView: some View {
        // WARNING: DO NOT ADD NavigationView HERE!
        // iOS Share Extension automatically provides its own navigation container.
        // Adding NavigationView causes duplicate headers - this is a SHARE EXTENSION, not a regular app!
        VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Select Items to Save")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Choose places from your import")
                        .font(.system(.subheadline))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom)
            
            // Content
            if isLoading {
                Spacer()
                PremiumLoadingView(
                    title: "Loading places...",
                    subtitle: "Preparing your selections"
                )
                Spacer()
            } else if places.isEmpty {
                Spacer()
                VStack(spacing: 24) {
                    // Animated illustration
                    ZStack {
                        // Background circle with Ocean Teal gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.oceanTeal.opacity(0.15), Color.oceanTeal.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(1.1)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                                value: true
                            )
                        
                        // Main icon
                        Image(systemName: "map.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(Color.oceanTeal)
                            .overlay(
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.coralHeart)
                                            .frame(width: 28, height: 28)
                                    )
                                    .offset(x: 20, y: -20)
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text("No Places Detected")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.deepNavy)
                        
                        Text("We couldn't find any location tags in this content.\nTry sharing a post that mentions specific places.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    
                    // Helpful tip
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.sunsetGold)
                        
                        Text("Tip: Look for posts with location pins or place names")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.sunsetGold.opacity(0.08))
                    )
                }
                .padding(.horizontal, 32)
                Spacer()
            } else {
                // Places List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(places) { place in
                            PlaceSelectionCard(
                                place: place,
                                isSelected: selectedPlaceIds.contains(place.id)
                            ) {
                                togglePlaceSelection(place.id)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for bottom button
                }
                
                // Bottom Action Area
                VStack(spacing: 12) {
                    SelectionToggleButtons(
                        totalCount: places.count,
                        selectedCount: selectedPlaceIds.count,
                        onSelectAll: selectAllPlaces,
                        onDeselectAll: clearAllPlaces
                    )
                    
                    PremiumButton(
                        "Add (\(selectedPlaceIds.count))",
                        style: .primary,
                        isEnabled: !selectedPlaceIds.isEmpty
                    ) {
                        proceedToPlaceCollectionSelection()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(
                    Color(.systemBackground)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        // Navigation modifiers removed - iOS provides them
    }
    
    // MARK: - PlaceCollection Selection View
    
    private var collectionSelectionView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    selectedPlacesPill
                    collectionsContent
                }
            }
            bottomActionBar
        }
        .task {
            if collections.isEmpty {
                await loadPlaceCollections()
            }
        }
    }
    
    private var selectedPlacesPill: some View {
        VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // Proper icon with coral color
                    ZStack {
                        Circle()
                            .fill(Color.coralHeart.opacity(0.12))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.coralHeart)
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        if let firstPlace = places.first(where: { selectedPlaceIds.contains($0.id) }) {
                            Text(firstPlace.displayName)
                                .font(.system(size: 17, weight: .medium, design: .default))
                                .foregroundColor(Color(hex: "1B2B4D")) // Deep Navy
                                .lineLimit(1)
                        }
                        
                        if selectedPlaceIds.count > 1 {
                            Text("+ \(selectedPlaceIds.count - 1) more places selected")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showExpandedLocations.toggle()
                        }
                        // Medium haptic for important interaction
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    }) {
                        ZStack {
                            // Premium gradient background
                            Circle()
                                .fill(Color.coralGradient)
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.coralHeart.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            // Animated chevron
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(showExpandedLocations ? 180 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showExpandedLocations)
                        }
                        .scaleEffect(showExpandedLocations ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: showExpandedLocations)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    // Premium background with Coral Heart 8% opacity as per design spec
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.coralHeart.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.coralHeart.opacity(0.12), lineWidth: 1)
                        )
                )
                .shadow(color: Color.coralHeart.opacity(0.1), radius: 12, x: 0, y: 4)
                .zIndex(1) // Keep pill above expanded content
                
                // Expanded locations list - visually connected
                if showExpandedLocations {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(places.filter { selectedPlaceIds.contains($0.id) }.enumerated()), id: \.element.id) { index, place in
                            HStack(spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.brandCaption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .trailing)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(place.displayName)
                                        .font(.brandBodyEmphasis)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    if let location = place.location {
                                        Text(location)
                                            .font(.brandCaption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(12)
                    .padding(.top, 8) // Add padding to create visual connection
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.coralHeart.opacity(0.04)) // Lighter background to match pill
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.coralHeart.opacity(0.08), lineWidth: 1)
                            )
                    )
                    .offset(y: -12) // Overlap more with pill for visual connection
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showExpandedLocations)
                }
                
            // Section title
            Text("Select Collections")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(Color(hex: "1B2B4D"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var collectionsContent: some View {
        Group {
            if isLoading {
                PremiumLoadingView(
                    title: "Loading collections...",
                    subtitle: "Getting your collections ready"
                )
                .frame(height: 300)
            } else if collections.isEmpty {
                VStack(spacing: 28) {
                    // Animated illustration for empty collections
                    ZStack {
                        // Background circle with Ocean Teal gradient
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.oceanTeal.opacity(0.2), Color.oceanTeal.opacity(0.08)],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 140, height: 140)
                            .scaleEffect(1.05)
                            .animation(
                                .easeInOut(duration: 3.0)
                                .repeatForever(autoreverses: true),
                                value: true
                            )
                        
                        // Collection stack illustration
                        VStack(spacing: -8) {
                            // Back collection card
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.oceanTeal.opacity(0.3))
                                .frame(width: 48, height: 32)
                                .rotationEffect(.degrees(-8))
                                .offset(x: -4, y: 4)
                            
                            // Middle collection card
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.oceanTeal.opacity(0.5))
                                .frame(width: 48, height: 32)
                                .rotationEffect(.degrees(4))
                                .offset(x: 2, y: -2)
                            
                            // Front collection card with plus
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.oceanTeal)
                                .frame(width: 48, height: 32)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    VStack(spacing: 16) {
                        Text("Create Your First Collection")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color.deepNavy)
                            .multilineTextAlignment(.center)
                        
                        Text("Collections help you organize places into themes like \"Must Visit\" or \"Weekend Trips\"")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 8)
                        
                        // Create first collection CTA
                        PremiumButton(
                            "Create First Collection",
                            style: .primary,
                            isEnabled: true
                        ) {
                            // Medium haptic for new collection
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            currentStep = .creatingPlaceCollection
                        }
                        .frame(width: 200)
                    }
                }
                .padding(.horizontal, 32)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(collections) { collection in
                            GridCollectionCard(
                                collection: collection,
                                isSelected: selectedPlaceCollectionIds.contains(collection.id)
                            ) {
                                togglePlaceCollectionSelection(collection.id)
                                // Haptic feedback on selection
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                        }
                        
                    // New PlaceCollection Card
                    NewCollectionCard {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        currentStep = .creatingPlaceCollection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
        }
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
                // Add subtle separator for depth
                Rectangle()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 0.5)
                
                VStack {
                    PremiumButton(
                        selectedPlaceCollectionIds.isEmpty ? "Add to Collection" : 
                        (selectedPlaceCollectionIds.count == 1 ? "Add to Collection" : "Add to Collections (\(selectedPlaceCollectionIds.count))"),
                        style: .primary,
                        isEnabled: !selectedPlaceCollectionIds.isEmpty
                    ) {
                        // Show success view first, then call onSave
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSuccessView = true
                        }
                        
                        // Strong haptic feedback for primary action
                        let successFeedback = UINotificationFeedbackGenerator()
                        successFeedback.notificationOccurred(.success)
                        
                        // Call save after brief delay for animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let placeIds = Array(selectedPlaceIds)
                            let collectionIds = Array(selectedPlaceCollectionIds)
                            onSave(placeIds, collectionIds)
                        }
                    }
                    .frame(height: 56) // Premium height for better touch target
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32) // More bottom padding for premium feel
            }
            .background(
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    
    // MARK: - New PlaceCollection View
    
    @ViewBuilder
    private var newPlaceCollectionView: some View {
        NewPlaceCollectionView { collection in
            collections.append(collection)
            selectedPlaceCollectionIds.insert(collection.id)
            
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .selectingPlaceCollections
            }
        } onCancel: {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .selectingPlaceCollections
            }
        }
    }
    
    // MARK: - Success View
    
    @ViewBuilder
    private var successView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success animation
            ZStack {
                // Multiple expanding celebration rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.coralHeart.opacity(0.3), Color.oceanTeal.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3 - CGFloat(index)
                        )
                        .frame(width: 80 + CGFloat(index * 40))
                        .scaleEffect(showSuccessView ? (1.2 + Double(index) * 0.3) : 0.8)
                        .opacity(showSuccessView ? 0 : 0.8)
                        .animation(
                            .easeOut(duration: 1.2 + Double(index) * 0.2)
                            .delay(Double(index) * 0.15),
                            value: showSuccessView
                        )
                }
                
                // Rotating particles/dots
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(Color.coralHeart.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .offset(x: 40)
                        .rotationEffect(.degrees(Double(index) * 45))
                        .scaleEffect(showSuccessView ? 1.5 : 0)
                        .opacity(showSuccessView ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.0)
                            .delay(0.3 + Double(index) * 0.05),
                            value: showSuccessView
                        )
                }
                
                // Success checkmark with bounce
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.coralHeart, Color.coralHeart.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72)
                        .shadow(color: .coralHeart.opacity(0.4), radius: 20, x: 0, y: 8)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showSuccessView ? 1.0 : 0)
                        .rotationEffect(.degrees(showSuccessView ? 0 : -180))
                }
                .scaleEffect(showSuccessView ? 1.0 : 0.3)
                .opacity(showSuccessView ? 1.0 : 0.0)
                .animation(
                    .interpolatingSpring(stiffness: 200, damping: 10)
                    .delay(0.1),
                    value: showSuccessView
                )
            }
            .onAppear {
                // Haptic feedback
                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                impactHeavy.impactOccurred()
                
                // Additional light impacts for celebration feel
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    let impactLight = UIImpactFeedbackGenerator(style: .light)
                    impactLight.impactOccurred()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    let impactLight = UIImpactFeedbackGenerator(style: .light)
                    impactLight.impactOccurred()
                }
            }
            
            // Success Message with staggered animation
            VStack(spacing: 12) {
                Text("Success!")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color.deepNavy)
                    .scaleEffect(showSuccessView ? 1.0 : 0.8)
                
                Text("Added \(selectedPlaceIds.count) place\(selectedPlaceIds.count == 1 ? "" : "s") to \(selectedPlaceCollectionIds.count) collection\(selectedPlaceCollectionIds.count == 1 ? "" : "s")")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .opacity(showSuccessView ? 1.0 : 0.0)
            .offset(y: showSuccessView ? 0 : 30)
            .animation(
                .interpolatingSpring(stiffness: 100, damping: 15)
                .delay(0.4),
                value: showSuccessView
            )
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func loadPlaces() async {
        isLoading = true
        
        do {
            // Convert result places to selection format
            let result = try await apiClient.getTaskResult(taskId)
            let loadedPlaces = result.places.map { place in
                PlaceWithSelection(
                    id: UUID().uuidString,
                    name: place.name,
                    location: place.location,
                    placeType: place.placeType,
                    confidenceScore: place.confidenceScore,
                    googlePlaceId: place.googlePlaceId,
                    categoryColor: "FF6B7A"
                )
            }
            await MainActor.run {
                self.places = loadedPlaces
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load places: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }
    
    private func loadPlaceCollections() async {
        isLoading = true
        
        do {
            let loadedPlaceCollections = try await apiClient.getAllCollections()
            await MainActor.run {
                self.collections = loadedPlaceCollections
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load collections: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }
    
    private func togglePlaceSelection(_ placeId: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedPlaceIds.contains(placeId) {
                selectedPlaceIds.remove(placeId)
            } else {
                selectedPlaceIds.insert(placeId)
            }
        }
    }
    
    private func togglePlaceCollectionSelection(_ collectionId: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedPlaceCollectionIds.contains(collectionId) {
                selectedPlaceCollectionIds.remove(collectionId)
            } else {
                selectedPlaceCollectionIds.insert(collectionId)
            }
        }
    }
    
    private func selectAllPlaces() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedPlaceIds = Set(places.map { $0.id })
        }
    }
    
    private func clearAllPlaces() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedPlaceIds.removeAll()
        }
    }
    
    private func proceedToPlaceCollectionSelection() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .selectingPlaceCollections
        }
        
        // Load collections if not already loaded
        if collections.isEmpty {
            Task {
                await loadPlaceCollections()
            }
        }
    }

}
// MARK: - Extension Views

struct NewPlaceCollectionView: View {
    let onSave: (PlaceCollection) -> Void
    let onCancel: () -> Void
    
    @StateObject private var apiClient = APIClient()
    @State private var collectionName = ""
    @State private var collectionDescription = ""
    @State private var selectedCoverImage: CoverImageOption = .autoGenerated
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum CoverImageOption {
        case autoGenerated
        case food
        case nature
        case urban
        case europe
        
        var displayName: String {
            switch self {
            case .autoGenerated: return "Auto-generated from video"
            case .food: return "Food & Dining"
            case .nature: return "Nature & Parks"
            case .urban: return "Urban & Architecture"
            case .europe: return "Europe & Travel"
            }
        }
        
        var coverImageUrl: String? { nil }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            PlaceSectionHeader(
                "New PlaceCollection",
                subtitle: "Create a new collection to organize your places"
            )
            
            ScrollView {
                VStack(spacing: 24) {
                    // Cover Image Selection - Reduced Prominence
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cover Image")
                            .font(.system(size: 15, weight: .semibold))  // Field label standard
                            .foregroundColor(Color.deepNavy)
                        
                        // Smaller, more subtle cover preview
                        ZStack {
                            // Always show theme gradient placeholder for new collection cover
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.themeGradient(for: "coral"))
                                .frame(height: 120)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.85))
                                )
                        }
                        .frame(height: 120)
                        
                        // Smaller, secondary style edit button
                        CompactPremiumButton("Edit Image") {
                            // TODO: Image picker or preset selection
                        }
                        .frame(height: 44)  // Smaller height
                    }
                    
                    // Name Input - iOS Standard
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 15, weight: .semibold))  // Field label standard
                            .foregroundColor(Color.deepNavy)
                        
                        TextField("e.g., Amsterdam 2025", text: $collectionName)
                            .font(.system(size: 17, weight: .regular))  // iOS standard input
                            .foregroundColor(Color.deepNavy)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(height: 48)  // iOS standard height
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "F2F2F7"))  // iOS standard gray
                            )
                    }
                    
                    // Description Input (Optional) - iOS Standard
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.system(size: 15, weight: .semibold))  // Field label standard
                            .foregroundColor(Color.deepNavy)
                        
                        ZStack(alignment: .topLeading) {
                            // Background for TextEditor
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "F2F2F7"))  // iOS standard gray
                                .frame(height: 88)  // iOS standard multiline height
                            
                            // Placeholder text
                            if collectionDescription.isEmpty {
                                Text("Add a description for this collection")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(Color.deepNavy.opacity(0.6))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 14)
                                    .allowsHitTesting(false)
                            }
                            
                            // TextEditor for multiline input
                            TextEditor(text: $collectionDescription)
                                .font(.system(size: 17, weight: .regular))  // iOS standard input
                                .foregroundColor(Color.deepNavy)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .scrollContentBackground(.hidden)  // Hide default background
                                .background(Color.clear)
                                .frame(height: 88)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                PremiumButton(
                    "Create PlaceCollection",
                    style: .primary,
                    isLoading: isCreating,
                    isEnabled: !collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    createPlaceCollection()
                }
                
                CompactPremiumButton("Cancel") {
                    onCancel()
                }
            }
            .padding()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createPlaceCollection() {
        Task {
            isCreating = true
            
            do {
                let collection = try await apiClient.createCollection(
                    name: collectionName.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: collectionDescription.isEmpty ? nil : collectionDescription,
                    coverImageUrl: selectedCoverImage.coverImageUrl,
                    colorTheme: "coral",
                    tags: []
                )
                
                await MainActor.run {
                    isCreating = false
                    
                    // Haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    
                    onSave(collection)
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Failed to create collection: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Grid Collection Card

struct GridCollectionCard: View {
    let collection: PlaceCollection
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 0) {
                // Cover Image with gradient overlay
                ZStack {
                    // Background
                    Rectangle()
                        .fill(Color.themeGradient(for: collection.colorTheme ?? "coral"))
                    
                    // Cover image
                    AsyncImage(url: URL(string: collection.coverImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.themeGradient(for: collection.colorTheme ?? "coral"))
                    }
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.5)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    
                    // Selection overlay
                    if isSelected {
                        Rectangle()
                            .fill(Color.coralHeart.opacity(0.2))
                    }
                    
                    // Content overlay
                    VStack {
                        HStack {
                            Spacer()
                            if isSelected {
                                ZStack {
                                    Circle()
                                        .fill(Color.coralHeart)
                                        .frame(width: 24, height: 24)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(8)
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(collection.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text("\(collection.placeCount) places")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                    }
                }
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.coralHeart : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - New Collection Card

struct NewCollectionCard: View {
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.warmWhite, Color.warmWhite.opacity(0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.oceanTeal.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color.oceanTeal)
                        .symbolRenderingMode(.hierarchical)
                }
                
                Text("Create New")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.deepNavy)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.warmWhite, Color.warmWhite.opacity(0.98)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                Color.oceanTeal,
                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                            )
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Visual Effect View Helper

struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect?
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

// MARK: - Preview

#Preview {
    PremiumPlaceSelectionView(
        taskId: "sample-task",
        onSave: { _, _ in },
        onCancel: {}
    )
}
