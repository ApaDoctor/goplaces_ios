//
//  PlaceDetailView.swift
//  GoPlaces
//
//  Created by Volodymyr Piskun on 03.09.2025.
//

import SwiftUI
import SwiftData
import MapKit

struct PlaceDetailView: View {
    
    // MARK: - Properties
    let place: Place
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    @State private var showingAddToCollection = false
    @State private var scrollOffset: CGFloat = 0
    @Namespace private var namespace
    
    private var coordinate: CLLocationCoordinate2D {
        // Default coordinates (will be updated when coordinate support is added)
        CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    }
    
    private var hasValidCoordinates: Bool {
        place.hasValidCoordinates
    }
    
    private var shareText: String {
        var text = "📍 \(place.displayName)\n"
        
        if !place.displayAddress.isEmpty && place.displayAddress != AppConstants.Place.Defaults.unknownAddress {
            text += "\n🏠 \(place.displayAddress)"
        }
        
        if let rating = place.formattedRating {
            text += "\n⭐ \(rating) stars"
        }
        
        if let phone = place.phoneNumber, !phone.isEmpty {
            text += "\n📞 \(phone)"
        }
        
        if let website = place.website, !website.isEmpty {
            text += "\n🌐 \(website)"
        }
        
        text += "\n\n🔗 Original post: \(place.socialURL)"
        text += "\n\nShared via GoPlaces 📍"
        
        return text
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            // Background color that extends behind navigation
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // Main scrollable content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero carousel
                    heroSection
                    
                    // Content card that overlaps hero
                    contentCard
                        .offset(y: -40)
                        .padding(.bottom, -40)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Custom navigation overlay
            navigationOverlay
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddToCollection) {
            // Add to collection sheet will be implemented later
            Text("Add to Collection")
        }
        .alert("Delete Place", isPresented: $showingDeleteAlert) {
            deleteAlertContent
        } message: {
            Text("Are you sure you want to delete '\(place.displayName)'? This action cannot be undone.")
        }
    }
    
    private var heroSection: some View {
        GeometryReader { geometry in
            let minY = geometry.frame(in: .global).minY
            let height = geometry.size.height + max(0, minY)
            
            ZStack(alignment: .bottom) {
                // Hero carousel
                if let imageURL = place.photoURL {
                    HeroImageCarousel(
                        images: [imageURL]
                    )
                } else {
                    // Fallback placeholder
                    LinearGradient(
                        colors: [DesignSystem.Colors.coralHeart.opacity(0.6), DesignSystem.Colors.oceanTeal.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: height)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            Text(place.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                    )
                }
                
                // Gradient overlay for text readability
                LinearGradient(
                    colors: [.clear, .black.opacity(0.3)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .frame(height: UIScreen.main.bounds.height * 0.4)
            .clipped()
        }
        .frame(height: UIScreen.main.bounds.height * 0.4)
    }
    
    private var navigationOverlay: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
            
            Spacer()
            
            Menu {
                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.horizontal)
        .padding(.top, 50)
    }
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section with title and rating
            VStack(alignment: .leading, spacing: 16) {
                titleSection
                
                // Action buttons
                actionButtons
                
                Divider()
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            
            // Details sections
            VStack(alignment: .leading, spacing: 24) {
                // Description section removed - not in Place model
                
                // Hours and pricing - commented out for now as not in Place model
                // if place.openingHours != nil || place.priceLevel != nil {
                //     HoursAndPriceCard(
                //         openingHours: place.openingHours,
                //         priceLevel: place.priceLevel,
                //         averageCost: place.averageCost
                //     )
                // }
                
                detailsSection
                
                if hasValidCoordinates {
                    mapSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
        .padding(.horizontal)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category badge - removed as not in Place model
            
            // Place name
            Text(place.displayName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // Rating and review count
            if place.rating > 0 {
                HStack(spacing: 8) {
                    RatingBadge(rating: place.rating, reviewCount: nil, showReviewCount: false)
                }
            }
            
            // Status badge removed - not in Place model
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Add to collection button
            Button {
                HapticManager.shared.impact(intensity: 0.5)
                showingAddToCollection = true
            } label: {
                Label("Add to Collection", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DesignSystem.Colors.coralHeart)
                    )
            }
            
            // Share button
            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.coralHeart)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DesignSystem.Colors.coralHeart.opacity(0.1))
                    )
            }
            
            // Directions button
            if hasValidCoordinates {
                Button {
                    HapticManager.shared.impact(intensity: 0.5)
                    openInMaps()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.coralHeart)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DesignSystem.Colors.coralHeart.opacity(0.1))
                        )
                }
            }
        }
    }
    
    @ViewBuilder
    private var deleteAlertContent: some View {
        Button("Delete", role: .destructive) {
            deletePlace()
        }
        Button("Cancel", role: .cancel) { }
    }
    
    // MARK: - View Components
    private var placeInformationSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.defaultSpacing) {
            headerSection
            
            Divider()
            
            detailsSection
            
            if hasValidCoordinates {
                Divider()
                mapSection
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.smallSpacing) {
            Text(place.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let rating = place.formattedRating {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: "star.fill")
                            .foregroundColor(star <= Int(place.rating) ? .yellow : .gray.opacity(0.3))
                    }
                    Text("(\(rating))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Added \(place.addedDate, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Contact & Info")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Address
                if !place.displayAddress.isEmpty && place.displayAddress != AppConstants.Place.Defaults.unknownAddress {
                    DetailRow(
                        icon: "location.fill",
                        iconColor: DesignSystem.Colors.oceanTeal,
                        title: "Address",
                        content: place.displayAddress,
                        action: hasValidCoordinates ? {
                            HapticManager.shared.impact(intensity: 0.5)
                            openInMaps()
                        } : nil
                    )
                }
                
                // Phone Number
                if let phoneNumber = place.phoneNumber, !phoneNumber.isEmpty {
                    DetailRow(
                        icon: "phone.fill",
                        iconColor: .green,
                        title: "Phone",
                        content: phoneNumber,
                        action: {
                            HapticManager.shared.impact(intensity: 0.5)
                            callPhoneNumber(phoneNumber)
                        }
                    )
                }
                
                // Website
                if let website = place.website, !website.isEmpty {
                    DetailRow(
                        icon: "globe",
                        iconColor: .indigo,
                        title: "Website",
                        content: website,
                        action: {
                            HapticManager.shared.impact(intensity: 0.5)
                            openWebsite(website)
                        }
                    )
                }
                
                // Social URL
                if !place.socialURL.isEmpty {
                    DetailRow(
                        icon: "camera.fill",
                        iconColor: .purple,
                        title: "Original Post",
                        content: "View original post",
                        action: {
                            HapticManager.shared.impact(intensity: 0.5)
                            openSourceURL(place.socialURL)
                        }
                    )
                }
            }
        }
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Location")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    HapticManager.shared.impact(intensity: 0.5)
                    openInMaps()
                } label: {
                    Text("Get Directions")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.coralHeart)
                }
            }
            
            Map {
                Marker(place.displayName, coordinate: coordinate)
                    .tint(.red)
            }
            .mapStyle(.standard)
            .frame(height: 200)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Methods
    private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = place.displayName
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func callPhoneNumber(_ phoneNumber: String) {
        let cleanNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleanNumber)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite(_ website: String) {
        var urlString = website
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSourceURL(_ sourceURL: String) {
        // Try to open in Instagram app first if it's an Instagram URL
        if sourceURL.contains("instagram.com") {
            // Convert web URL to Instagram app URL
            var instagramAppURL = sourceURL
            if let webURL = URL(string: sourceURL),
               let components = URLComponents(url: webURL, resolvingAgainstBaseURL: false) {
                // Extract the path and convert to Instagram app scheme
                let path = components.path
                instagramAppURL = "instagram://\(path)"
                
                if let appURL = URL(string: instagramAppURL),
                   UIApplication.shared.canOpenURL(appURL) {
                    UIApplication.shared.open(appURL)
                    return
                }
            }
        }
        
        // Fallback to web URL
        if let url = URL(string: sourceURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func deletePlace() {
        modelContext.delete(place)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete place: \(error)")
        }
    }
}

// MARK: - Detail Row
private struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    let action: (() -> Void)?
    
    init(icon: String, iconColor: Color = DesignSystem.Colors.oceanTeal, title: String, content: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.content = content
        self.action = action
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(iconColor.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(content)
                        .font(.body)
                        .foregroundColor(action != nil ? .primary : .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}



#Preview {
    let samplePlace = Place(
        name: "Sample Restaurant",
        address: "123 Main St, City, State",
        socialURL: "https://instagram.com/sample",
        rating: 4.5,
        photoURL: "https://via.placeholder.com/400x250",
        phoneNumber: "+1 (555) 123-4567",
        website: "https://samplerestaurant.com"
    )
    
    PlaceDetailView(place: samplePlace)
        .modelContainer(SwiftDataStack.shared.container)
}