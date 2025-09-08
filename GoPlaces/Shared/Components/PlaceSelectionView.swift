//
//  PlaceSelectionView.swift
//  GoPlaces
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
            HStack(spacing: AppConstants.UI.defaultSpacing) {
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
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
                
                // Place info
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if !place.address.isEmpty {
                        Text(place.displayAddress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Rating if available
                    if let rating = place.formattedRating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption2)
                            Text(rating)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Place type indicator
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
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    let samplePlaces = [
        Place(
            name: "Central Park",
            address: "New York, NY 10024, USA",
            socialURL: "https://instagram.com/test",
            rating: 4.7,
            photoURL: nil,
            phoneNumber: nil,
            website: "https://www.centralparknyc.org"
        ),
        Place(
            name: "Sunset Beach Cafe",
            address: "123 Ocean Drive, Miami, FL 33139, USA", 
            socialURL: "https://instagram.com/test",
            rating: 4.5,
            photoURL: nil,
            phoneNumber: "+1 305-555-0123",
            website: "https://sunsetbeachcafe.com"
        ),
        Place(
            name: "Local Spot",
            address: "",
            socialURL: "https://instagram.com/test",
            rating: 0.0
        )
    ]
    
    PlaceSelectionView(
        places: samplePlaces,
        onSave: { places in
            print("Would save \(places.count) places")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}