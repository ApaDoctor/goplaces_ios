//
//  PlaceListView.swift
//  GoPlaces
//
//  Created by Assistant on 2025-09-06.
//

import SwiftUI
import SwiftData

struct PlaceListView: View {
    let places: [Place]
    var onPlaceTap: ((Place) -> Void)? = nil
    var embeddedInScroll: Bool = false
    // Toggle to show/hide search UI without deleting code
    private let isSearchVisible = false
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .dateAdded
    @State private var selectedCategory: PlaceCategory? = nil
    @State private var isSelectionMode = false
    @State private var selectedPlaces: Set<UUID> = []
    
    enum SortOrder: String, CaseIterable {
        case dateAdded = "Date Added"
        case name = "Name"
        case rating = "Rating"
        
        var icon: String {
            switch self {
            case .dateAdded: return "calendar"
            case .name: return "textformat"
            case .rating: return "star"
            }
        }
    }
    
    enum PlaceCategory: String, CaseIterable {
        case restaurant = "Restaurant"
        case cafe = "Cafe"
        case bar = "Bar"
        case shopping = "Shopping"
        case attraction = "Attraction"
        case hotel = "Hotel"
        
        var icon: String {
            switch self {
            case .restaurant: return "fork.knife"
            case .cafe: return "cup.and.saucer"
            case .bar: return "wineglass"
            case .shopping: return "bag"
            case .attraction: return "star.circle"
            case .hotel: return "bed.double"
            }
        }
    }
    
    private var filteredPlaces: [Place] {
        var filtered = places
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { place in
                place.displayName.localizedCaseInsensitiveContains(searchText) ||
                place.displayAddress.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Category filter - skip for now as Place model doesn't have categories
        
        // Sort
        switch sortOrder {
        case .dateAdded:
            filtered.sort { $0.addedDate > $1.addedDate }
        case .name:
            filtered.sort { $0.displayName < $1.displayName }
        case .rating:
            filtered.sort { $0.rating > $1.rating }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filters
            VStack(spacing: 12) {
                // Search bar (hidden via flag; keeps code intact)
                if isSearchVisible {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search places...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
                
                // Sort and filter controls
                HStack {
                    // Sort menu
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                Label(order.rawValue, systemImage: order.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: sortOrder.icon)
                            Text(sortOrder.rawValue)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.tertiarySystemBackground))
                        )
                    }
                    
                    Spacer()
                    
                    // Selection mode toggle
                    Button {
                        withAnimation {
                            isSelectionMode.toggle()
                            if !isSelectionMode {
                                selectedPlaces.removeAll()
                            }
                        }
                    } label: {
                        Text(isSelectionMode ? "Done" : "Select")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.oceanTeal)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
            
            // Places list
            if filteredPlaces.isEmpty {
                emptyState
            } else {
                if embeddedInScroll {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredPlaces, id: \.id) { place in
                            PlaceListRow(
                                place: place,
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedPlaces.contains(place.id),
                                onToggleSelection: {
                                    toggleSelection(for: place)
                                },
                                onTap: {
                                    if isSelectionMode {
                                        toggleSelection(for: place)
                                    } else {
                                        onPlaceTap?(place)
                                    }
                                }
                            )
                            .contentShape(Rectangle())
                            
                            if place.id != filteredPlaces.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredPlaces, id: \.id) { place in
                                PlaceListRow(
                                    place: place,
                                    isSelectionMode: isSelectionMode,
                                    isSelected: selectedPlaces.contains(place.id),
                                    onToggleSelection: {
                                        toggleSelection(for: place)
                                    },
                                    onTap: {
                                        if isSelectionMode {
                                            toggleSelection(for: place)
                                        } else {
                                            onPlaceTap?(place)
                                        }
                                    }
                                )
                                .contentShape(Rectangle())
                                
                                if place.id != filteredPlaces.last?.id {
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No places found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func toggleSelection(for place: Place) {
        if selectedPlaces.contains(place.id) {
            selectedPlaces.remove(place.id)
        } else {
            selectedPlaces.insert(place.id)
        }
        HapticManager.shared.impact(intensity: 0.3)
    }
}

// MARK: - Place List Row
private struct PlaceListRow: View {
    let place: Place
    let isSelectionMode: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Selection checkbox
            if isSelectionMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? DesignSystem.Colors.coralHeart : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Place content
            PlaceRow(
                place: place,
                onTap: onTap
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}