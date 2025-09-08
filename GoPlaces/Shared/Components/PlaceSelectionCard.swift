//
//  PlaceSelectionCard.swift
//  GoPlaces
//
//  Premium place selection card with colorful category icons
//  Created by Volodymyr Piskun on 05.09.2025.
//

import SwiftUI

struct PlaceSelectionCard: View {
    let place: PlaceWithSelection
    let isSelected: Bool
    let onToggleSelection: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onToggleSelection()
        }) {
            HStack(spacing: 14) {
                // Icon Stack with Category and Location
                HStack(spacing: -12) {
                    // Category Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: place.categoryColor))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: place.sfSymbolName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Location indicator overlapping
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.oceanTeal)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .offset(x: -4)
                }
                
                // Place Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(place.displayName)
                            .font(.system(.subheadline, design: .default, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Confidence indicator
                        if place.isHighConfidence {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.successGreen)
                        } else {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text(place.displayAddress)
                            .font(.brandCaption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        if let placeType = place.placeType {
                            Text("•")
                                .font(.brandCaption)
                                .foregroundColor(.secondary)
                            
                            Text(placeType.capitalized)
                                .font(.brandCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Selection indicator with inner glow
                ZStack {
                    // Inner glow effect when selected
                    if isSelected {
                        Circle()
                            .fill(Color.coralHeart.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .blur(radius: 4)
                    }
                    
                    // Checkbox border
                    Circle()
                        .stroke(isSelected ? Color.coralHeart : Color(hex: "E5E5E7"), lineWidth: isSelected ? 2 : 1)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        // Gradient fill when selected
                        Circle()
                            .fill(Color.coralGradient)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .scaleEffect(isSelected ? 1.0 : 0.5)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)  // Increased from 12 to 16 for better touch target
            .frame(minHeight: 76)  // Ensure minimum height for touch targets
            .background(
                RoundedRectangle(cornerRadius: 16)  // Strict 16pt radius
                    .fill(Color.warmWhite)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)  // Enhanced shadow
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.coralHeart.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Compact Place Card (for final confirmation)

struct CompactPlaceCard: View {
    let place: PlaceWithSelection
    
    var body: some View {
        HStack(spacing: 12) {
            // Smaller category icon
            ZStack {
                Circle()
                    .fill(Color(hex: place.categoryColor))
                    .frame(width: 32, height: 32)
                
                Image(systemName: place.sfSymbolName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Place info
            VStack(alignment: .leading, spacing: 2) {
                Text(place.displayName)
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(place.displayAddress)
                    .font(.system(.caption2))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - List Toggle Buttons

struct SelectionToggleButtons: View {
    let totalPlaces: Int
    let selectedPlaces: Int
    let onSelectAll: () -> Void
    let onClearAll: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            CompactPremiumButton("Select All", style: .tertiary) {
                onSelectAll()
            }
            
            CompactPremiumButton("Clear All", style: .tertiary) {
                onClearAll()
            }
            
            Spacer()
            
            // Selection counter
            if selectedPlaces > 0 {
                Text("\(selectedPlaces) selected")
                    .font(.brandCaption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.coralHeart.opacity(0.1))
                    )
            }
        }
    }
}

// MARK: - Section Header

struct PlaceSectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.brandHeadline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.brandBody)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Place Selection Cards") {
    let samplePlace = PlaceWithSelection(
        id: "1",
        name: "Café Winkel 43",
        location: "Jordaan • Amsterdam",
        placeType: "cafe",
        confidenceScore: 0.95,
        googlePlaceId: "ChIJ123",
        categoryColor: "#FF8A5B",
        iconName: "cup.and.saucer.fill"
    )
    
    let lowConfidencePlace = PlaceWithSelection(
        id: "2",
        name: "Van Gogh Museum",
        location: "Museumplein • Amsterdam",
        placeType: "museum",
        confidenceScore: 0.65,
        googlePlaceId: "ChIJ456",
        categoryColor: "#9B59B6",
        iconName: "building.columns.fill"
    )
    
    VStack(spacing: 16) {
        PlaceSectionHeader(
            title: "Select Items to Save",
            subtitle: "Choose places from your import"
        )
        
        PlaceSelectionCard(place: samplePlace, isSelected: false) {}
        PlaceSelectionCard(place: samplePlace, isSelected: true) {}
        PlaceSelectionCard(place: lowConfidencePlace, isSelected: false) {}
        
        SelectionToggleButtons(
            totalPlaces: 4,
            selectedPlaces: 2,
            onSelectAll: {},
            onClearAll: {}
        )
        
        VStack(spacing: 8) {
            CompactPlaceCard(place: samplePlace)
            CompactPlaceCard(place: lowConfidencePlace)
        }
    }
    .padding()
    .background(Color.warmWhite)
}