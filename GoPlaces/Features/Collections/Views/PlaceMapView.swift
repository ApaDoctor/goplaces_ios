//
//  PlaceMapView.swift
//  GoPlaces
//
//  Created by Assistant on 2025-09-06.
//

import SwiftUI
import MapKit
import SwiftData

struct PlaceMapView: View {
    let places: [Place]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedPlace: Place?
    @State private var mapType: MKMapType = .standard
    @State private var showingUserLocation = false
    
    var body: some View {
        ZStack {
            // Map
            MapViewRepresentable(
                places: places,
                region: $region,
                selectedPlace: $selectedPlace,
                mapType: mapType,
                showingUserLocation: showingUserLocation
            )
            .ignoresSafeArea(edges: .bottom)
            
            // Map controls overlay
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Map type toggle
                        Button {
                            withAnimation {
                                switch mapType {
                                case .standard:
                                    mapType = .hybrid
                                case .hybrid:
                                    mapType = .satellite
                                case .satellite:
                                    mapType = .standard
                                default:
                                    mapType = .standard
                                }
                            }
                        } label: {
                            Image(systemName: mapTypeIcon)
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        
                        // User location toggle
                        Button {
                            showingUserLocation.toggle()
                        } label: {
                            Image(systemName: showingUserLocation ? "location.fill" : "location")
                                .font(.system(size: 18))
                                .foregroundColor(showingUserLocation ? DesignSystem.Colors.oceanTeal : .primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        
                        // Zoom to fit all
                        Button {
                            zoomToFitAllPlaces()
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Selected place card
                if let place = selectedPlace {
                    PlaceMapCard(place: place) {
                        selectedPlace = nil
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding()
                }
            }
        }
        .onAppear {
            zoomToFitAllPlaces()
        }
    }
    
    private var mapTypeIcon: String {
        switch mapType {
        case .standard:
            return "map"
        case .hybrid:
            return "map.fill"
        case .satellite:
            return "globe"
        default:
            return "map"
        }
    }
    
    private func zoomToFitAllPlaces() {
        // For now, just center on a default location
        // In a real app, we'd calculate the region to fit all places with coordinates
        withAnimation {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
    }
}

// MARK: - MapView Representable
struct MapViewRepresentable: UIViewRepresentable {
    let places: [Place]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedPlace: Place?
    let mapType: MKMapType
    let showingUserLocation: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showingUserLocation
        mapView.mapType = mapType
        
        // Add annotations for places
        // Note: Since Place model doesn't have coordinates yet, we're using dummy data
        let annotations = createAnnotations()
        mapView.addAnnotations(annotations)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        mapView.showsUserLocation = showingUserLocation
        
        // Update region if needed
        if !mapView.region.isEqual(region) {
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createAnnotations() -> [MKPointAnnotation] {
        // Create dummy annotations for now
        // In real app, would use actual place coordinates
        return places.enumerated().map { index, place in
            let annotation = MKPointAnnotation()
            annotation.title = place.displayName
            annotation.subtitle = place.displayAddress
            // Dummy coordinates spread around SF
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: 37.7749 + Double.random(in: -0.05...0.05),
                longitude: -122.4194 + Double.random(in: -0.05...0.05)
            )
            return annotation
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? MKPointAnnotation,
                  let title = annotation.title else { return }
            
            // Find the corresponding place
            if let place = parent.places.first(where: { $0.displayName == title }) {
                withAnimation {
                    parent.selectedPlace = place
                }
                HapticManager.shared.impact(intensity: 0.5)
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }
}

// MARK: - Place Map Card
struct PlaceMapCard: View {
    let place: Place
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(place.displayAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                // Rating
                if place.rating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", place.rating))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // Actions
                Button {
                    // Open in maps
                } label: {
                    Label("Directions", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(DesignSystem.Colors.coralHeart)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Region Extension
extension MKCoordinateRegion {
    func isEqual(_ other: MKCoordinateRegion) -> Bool {
        return abs(center.latitude - other.center.latitude) < 0.0001 &&
               abs(center.longitude - other.center.longitude) < 0.0001 &&
               abs(span.latitudeDelta - other.span.latitudeDelta) < 0.0001 &&
               abs(span.longitudeDelta - other.span.longitudeDelta) < 0.0001
    }
}