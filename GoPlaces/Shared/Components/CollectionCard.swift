//
//  CollectionCard.swift
//  GoPlaces
//
//  Premium collection card component with beautiful styling
//  Created by Volodymyr Piskun on 05.09.2025.
//

import SwiftUI

struct CollectionCard: View {
    let collection: PlaceCollection
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var imageLoaded = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Cover Image
                ZStack {
                    // Background gradient while image loads
                    Rectangle()
                        .fill(Color.themeGradient(for: collection.themeColor))
                        .opacity(imageLoaded ? 0 : 1)
                    
                    // Cover image
                    AsyncImage(url: URL(string: collection.coverImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(16/10, contentMode: .fill) // Optimal for travel photos
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    imageLoaded = true
                                }
                            }
                    } placeholder: {
                        Rectangle()
                            .fill(Color.themeGradient(for: collection.themeColor))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                    
                    // Selection overlay
                    if isSelected {
                        Rectangle()
                            .fill(Color.coralHeart.opacity(0.2))
                        
                        // Selection checkmark positioned safely within bounds
                        VStack {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.coralHeart)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            Spacer()
                        }
                        .padding(12)
                    }
                }
                .frame(height: 120)
                .clipShape(
                    .rect(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16
                    )
                )
                
                // Collection Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(collection.name)
                            .font(.system(.subheadline, design: .default, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Recently updated indicator
                        if collection.isRecentlyUpdated {
                            Circle()
                                .fill(Color.coralHeart)
                                .frame(width: 6, height: 6)
                        }
                    }
                    
                    Text(collection.placeCountText)
                        .font(.brandCaption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.coralHeart : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .animation(.easeInOut(duration: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Grid Collection Card (smaller variant)

struct GridCollectionCard: View {
    let collection: PlaceCollection
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var imageLoaded = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 0) {
                // Cover Image (square for grid) with gradient overlay
                ZStack {
                    // Determine if we actually have a cover image URL
                    let hasCoverImage = !(collection.coverImageUrl ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    // Background while image loads
                    Rectangle()
                        .fill(Color.themeGradient(for: collection.themeColor))
                        .opacity(imageLoaded ? 0 : 1)
                    
                    // Cover image
                    AsyncImage(url: URL(string: collection.coverImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    imageLoaded = true
                                }
                            }
                    } placeholder: {
                        Rectangle()
                            .fill(Color.themeGradient(for: collection.themeColor))
                            .aspectRatio(1, contentMode: .fill)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                    
                    // Enhanced gradient overlay only when there is an actual image
                    if hasCoverImage {
                        ZStack {
                            // Primary gradient - subtle fade from transparent to dark
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.clear,
                                    Color.black.opacity(0.15),
                                    Color.black.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            // Bottom shadow gradient for text area
                            VStack {
                                Spacer()
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.black.opacity(0.8)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 60)
                            }
                        }
                    }
                    
                    // Selection overlay
                    if isSelected {
                        Rectangle()
                            .fill(Color.coralHeart.opacity(0.2))
                    }
                    
                    // Content overlay
                    VStack {
                        HStack {
                            Spacer()
                            // Selection checkmark - constrained to safe area
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
                        
                        // Place info on enhanced gradient
                        VStack(alignment: .leading, spacing: 3) {
                            Text(collection.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 0.5)
                            
                            Text(collection.placeCountText)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
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
            .animation(.easeInOut(duration: 0.3), value: isSelected)
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
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 0) {
                ZStack {
                    // Background with gradient matching other cards
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.warmWhite, Color.warmWhite.opacity(0.98)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Content centered in the card
                    VStack(spacing: 16) {
                        // Premium icon with Ocean Teal accent
                        ZStack {
                            // Subtle gradient background
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
                        .scaleEffect(isPressed ? 0.9 : (isHovering ? 1.05 : 1.0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                        .animation(.easeInOut(duration: 0.2), value: isHovering)
                        
                        Text("Create New")
                            .font(.system(size: 15, weight: .medium, design: .default))
                            .foregroundColor(Color.deepNavy)
                    }
                }
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            Color.oceanTeal,
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                )
            }
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                isHovering = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isHovering = false
                }
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview("Collection Cards") {
    let sampleCollection = PlaceCollection(
        id: "sample",
        name: "Amsterdam",
        description: "Beautiful canals and cafés",
        coverImageUrl: "https://images.unsplash.com/photo-1534351590666-13e3e96b5017",
        placeCount: 12,
        createdAt: Date(),
        updatedAt: Date(),
        colorTheme: "coral",
        isFavorite: true,
        tags: ["europe", "canals"]
    )
    
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            CollectionCard(collection: sampleCollection, isSelected: false) {}
            CollectionCard(collection: sampleCollection, isSelected: true) {}
        }
        
        HStack(spacing: 16) {
            GridCollectionCard(collection: sampleCollection, isSelected: false) {}
            GridCollectionCard(collection: sampleCollection, isSelected: true) {}
            NewCollectionCard() {}
        }
    }
    .padding()
    .background(Color.warmWhite)
}