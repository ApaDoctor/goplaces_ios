//
//  PlaceSelectionView.swift
//  Share Extension
//
//  Place selection interface for Share Extension
//  Created by Volodymyr Piskun on 04.09.2025.
//

import SwiftUI

struct PlaceSelectionView: View {
    let places: [Place]
    let onSave: ([Place]) -> Void
    let onCancel: () -> Void
    
    @State private var selectedPlaces = Set<UUID>()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Found \(places.count) place\(places.count == 1 ? "" : "s")")
                    .font(.headline)
                
                Text("Select which places to save:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Places list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(places, id: \.id) { place in
                        PlaceSelectionRow(
                            place: place,
                            isSelected: selectedPlaces.contains(place.id)
                        ) { isSelected in
                            if isSelected {
                                selectedPlaces.insert(place.id)
                            } else {
                                selectedPlaces.remove(place.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 200)
            
            // Action buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Select All") {
                    if selectedPlaces.count == places.count {
                        selectedPlaces.removeAll()
                    } else {
                        selectedPlaces = Set(places.map { $0.id })
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundColor(.blue)
                
                Button("Save \(selectedPlaces.count) Place\(selectedPlaces.count == 1 ? "" : "s")") {
                    let placesToSave = places.filter { selectedPlaces.contains($0.id) }
                    onSave(placesToSave)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedPlaces.isEmpty)
            }
        }
        .padding()
        .onAppear {
            // Pre-select all places by default
            selectedPlaces = Set(places.map { $0.id })
        }
    }
}

struct PlaceSelectionRow: View {
    let place: Place
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onSelectionChanged(!isSelected)
        }) {
            rowContent
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var rowContent: some View {
        HStack(spacing: 12) {
            // Selection indicator
            selectionIndicator
            
            // Place info
            placeInfo
            
            Spacer()
            
            // Place type indicator
            placeTypeIndicator
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundView)
    }
    
    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isSelected ? .blue : .gray)
            .font(.title2)
    }
    
    private var placeInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(place.name.isEmpty ? "New Place" : place.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            if !place.address.isEmpty {
                Text(place.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Rating if available
            if place.rating > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text(String(format: "%.1f", place.rating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var placeTypeIndicator: some View {
        Group {
            if !place.address.isEmpty {
                Image(systemName: "location.circle")
                    .foregroundColor(.blue)
                    .font(.caption)
            } else {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
    }
}