//
//  MyPlacesView.swift
//  GoPlaces
//
//  Created by Volodymyr Piskun on 03.09.2025.
//

import SwiftUI
import SwiftData

struct MyPlacesView: View {
    
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Place.addedDate, order: .reverse) private var places: [Place]
    @StateObject private var viewModel: MyPlacesViewModel
    
    // MARK: - Initialization
    init() {
        // Initialize with default service - will be updated onAppear with proper context
        self._viewModel = StateObject(wrappedValue: MyPlacesViewModel())
    }
    
    @State private var searchText = ""
    @State private var showingAddPlace = false
    @State private var selectedPlace: Place?
    @State private var showingDeleteAlert = false
    @State private var placeToDelete: Place?
    
    var body: some View {
        NavigationView {
            Group {
                if filteredPlaces.isEmpty {
                    EmptyStateView()
                } else {
                    PlacesListView(
                        places: filteredPlaces,
                        onPlaceSelected: { place in
                            selectedPlace = place
                        },
                        onDeletePlace: { place in
                            placeToDelete = place
                            showingDeleteAlert = true
                        }
                    )
                }
            }
            .navigationTitle("My Places")
            .searchable(text: $searchText, prompt: "Search places...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPlace = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Place")
                }
            }
        }
        .sheet(isPresented: $showingAddPlace) {
            AddPlaceView()
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailView(place: place)
        }
        .alert("Delete Place", isPresented: $showingDeleteAlert, presenting: placeToDelete) { place in
            Button("Delete", role: .destructive) {
                deletePlace(place)
            }
            Button("Cancel", role: .cancel) { }
        } message: { place in
            Text("Are you sure you want to delete '\(place.displayName)'?")
        }
        .onAppear {
            viewModel.configure(with: modelContext)
            
            // Add sample place for testing PlaceDetailView if no places exist
            if places.isEmpty {
                let samplePlace = Place(
                    name: "Sample Restaurant",
                    address: "123 Main St, New York, NY 10001",
                    socialURL: "https://instagram.com/p/sample123",
                    rating: 4.5,
                    photoURL: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=250",
                    phoneNumber: "+1 (555) 123-4567",
                    website: "https://samplerestaurant.com"
                )
                modelContext.insert(samplePlace)
                try? modelContext.save()
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredPlaces: [Place] {
        if searchText.isEmpty {
            return places
        } else {
            return places.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText) ||
                place.address.localizedCaseInsensitiveContains(searchText) ||
                (place.phoneNumber?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    // MARK: - Methods
    private func deletePlace(_ place: Place) {
        Task {
            await viewModel.deletePlace(place)
        }
    }
}

// MARK: - Empty State View
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: AppConstants.UI.defaultSpacing) {
            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Places Yet")
                .font(.system(size: 28, weight: .semibold))
                .fontWeight(.semibold)
            
            Text("Start building your collection of favorite places by adding them from URLs or manually.")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Places List View
private struct PlacesListView: View {
    let places: [Place]
    let onPlaceSelected: (Place) -> Void
    let onDeletePlace: (Place) -> Void
    
    var body: some View {
        List {
            ForEach(places, id: \.id) { place in
                PlaceRowView(place: place)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onPlaceSelected(place)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            onDeletePlace(place)
                        }
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Place Row View
private struct PlaceRowView: View {
    let place: Place
    
    var body: some View {
        HStack(spacing: AppConstants.UI.defaultSpacing) {
            // Place Icon
            Image(systemName: "location.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            // Place Details
            VStack(alignment: .leading, spacing: 4) {
                Text(place.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                
                if !place.displayAddress.isEmpty && place.displayAddress != AppConstants.Place.Defaults.unknownAddress {
                    Text(place.displayAddress)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let rating = place.formattedRating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.yellow)
                            Text(rating)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(place.addedDate, style: .date)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MyPlacesView()
        .modelContainer(SwiftDataStack.shared.container)
}