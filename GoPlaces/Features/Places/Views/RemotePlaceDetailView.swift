//
//  RemotePlaceDetailView.swift
//  GoPlaces
//
//  Premium place detail screen that fetches data from API by place id
//

import SwiftUI
import UIKit

struct RemotePlaceDetailView: View {
    let placeId: String
    let titleFallback: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var api = APIClient()
    @State private var detail: PlaceDetailResponse? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showCollectionPicker = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            if let detail = detail {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        hero(detail)
                        content(detail)
                            .offset(y: -40)
                            .padding(.bottom, -40)
                    }
                }
                .ignoresSafeArea(edges: .top)
                .overlay(navigationOverlay, alignment: .top)
            } else if isLoading {
                VStack(spacing: 16) {
                    ProgressView().tint(DesignSystem.Colors.oceanTeal)
                    Text("Loading place...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.title)
                    Text(errorMessage ?? "Failed to load place")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Close") { dismiss() }
                        .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .task { await load() }
    }
    
    private func load() async {
        isLoading = true
        do {
            let d = try await api.getPlaceDetail(placeId: placeId)
            await MainActor.run {
                self.detail = d
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Sections
    private func hero(_ d: PlaceDetailResponse) -> some View {
        ZStack(alignment: .bottom) {
            if let first = d.photoUrls.first, let url = URL(string: first) {
                HeroImageCarousel(images: d.photoUrls)
                    .frame(height: UIScreen.main.bounds.height * 0.4)
            } else {
                LinearGradient(colors: [DesignSystem.Colors.coralHeart.opacity(0.6), DesignSystem.Colors.oceanTeal.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: UIScreen.main.bounds.height * 0.4)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.25)], startPoint: .center, endPoint: .bottom)
        }
        .frame(height: UIScreen.main.bounds.height * 0.4)
    }
    
    private func content(_ d: PlaceDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text(d.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                HStack(spacing: 8) {
                    if let rating = d.rating {
                        RatingBadge(rating: rating, reviewCount: d.reviewCount, showReviewCount: d.reviewCount != nil)
                    }
                    if let price = d.priceLevel {
                        Text(String(repeating: "$", count: min(price, 4)))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !d.address.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(DesignSystem.Colors.oceanTeal)
                        Text(d.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    Button {
                        showCollectionPicker = true
                    } label: {
                        Label("Add to Collection", systemImage: "plus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(DesignSystem.Colors.coralHeart))
                    }
                    
                    Button {
                        openInGoogleMaps(d)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Google Maps")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(DesignSystem.Colors.coralHeart)
                        .frame(height: 44)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(DesignSystem.Colors.coralHeart.opacity(0.1)))
                    }
                }
                Divider().padding(.vertical, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            
            VStack(alignment: .leading, spacing: 24) {
                if !d.description.isEmpty {
                    Text(d.description).font(.body).foregroundColor(.primary)
                }
                
                if d.openingHours != nil || d.priceLevel != nil || d.averageCost != nil {
                    HoursAndPriceCard(openingHours: d.openingHours, priceLevel: d.priceLevel, averageCost: d.averageCost)
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
        .sheet(isPresented: $showCollectionPicker) {
            if let d = detail {
                CollectionPickerSheet(placeId: d.id)
            }
        }
    }
    
    private var navigationOverlay: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 50)
    }
}

// MARK: - Helpers
extension RemotePlaceDetailView {
    private func openInGoogleMaps(_ d: PlaceDetailResponse) {
        // Prefer backend-provided URLs to avoid FE constructing them
        if let appUrlStr = d.googleMapsAppUrl, let appUrl = URL(string: appUrlStr), UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
            return
        }
        if let webUrlStr = d.googleMapsUrl, let webUrl = URL(string: webUrlStr) {
            UIApplication.shared.open(webUrl)
            return
        }
        // Prefer Google Place ID when available
        if let placeId = d.googlePlaceId, !placeId.isEmpty {
            if let url = URL(string: "comgooglemaps://?q=place_id:\(placeId)") , UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
            if let web = URL(string: "https://www.google.com/maps/search/?api=1&query=Google&query_place_id=\(placeId)") {
                UIApplication.shared.open(web)
                return
            }
        }
        // Next, prefer coordinates if available
        if let coords = d.coordinates {
            let lat = coords.lat
            let lng = coords.lng
            if let url = URL(string: "comgooglemaps://?q=\(lat),\(lng)&zoom=16") , UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
            if let web = URL(string: "https://www.google.com/maps/search/?api=1&query=\(lat),\(lng)") {
                UIApplication.shared.open(web)
                return
            }
        }
        // Fallback to address
        let query = d.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? d.name
        if let url = URL(string: "comgooglemaps://?q=\(query)") , UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }
        if let web = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)") {
            UIApplication.shared.open(web)
        }
    }
}

// MARK: - Collection Picker Sheet
private struct CollectionPickerSheet: View {
    let placeId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var api = APIClient()
    @State private var collections: [PlaceCollection] = []
    @State private var selected: Set<String> = []
    @State private var isLoading: Bool = true
    @State private var error: String? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading collections...")
                        .tint(DesignSystem.Colors.oceanTeal)
                } else if let error = error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(error).font(.subheadline).foregroundColor(.secondary)
                        Button("Close") { dismiss() }.buttonStyle(.bordered)
                    }
                    .padding()
                } else if collections.isEmpty {
                    VStack(spacing: 8) {
                        Text("No collections yet")
                        Text("Create one from the Collections tab")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(collections, id: \.id) { c in
                        HStack {
                            Text(c.name)
                            Spacer()
                            if selected.contains(c.id) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(DesignSystem.Colors.coralHeart)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selected.contains(c.id) { selected.remove(c.id) } else { selected.insert(c.id) }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Choose Collections")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { Task { await save() } }
                        .disabled(selected.isEmpty)
                }
            }
        }
        .task { await load() }
    }
    
    private func load() async {
        do {
            let cols = try await api.getAllCollections()
            await MainActor.run {
                self.collections = cols
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func save() async {
        guard !selected.isEmpty else { return }
        do {
            _ = try await api.addPlacesToCollections(placeIds: [placeId], collectionIds: Array(selected))
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
    }
}

#Preview {
    RemotePlaceDetailView(placeId: "amsterdam-2024_place_1", titleFallback: "Sample")
}


