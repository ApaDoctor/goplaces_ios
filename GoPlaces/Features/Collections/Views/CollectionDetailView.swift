//
//  CollectionDetailView.swift
//  GoPlaces
//
//  Created by Assistant on 2025-09-06.
//

import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    let collection: PlaceCollection
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CollectionDetailViewModel()
    @State private var selectedTab: CollectionTab = .list
    @State private var showingAddPlace = false
    @State private var showingEditMode = false
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirm = false
    @Namespace private var animationNamespace
    @State private var pendingCoverPicker = false
    @State private var pendingCoverImage: UIImage? = nil
    
    private var shareText: String {
        return viewModel.generateShareContent(
            collectionName: collection.name,
            collectionDescription: collection.description
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with collection info
                    collectionHeader
                    
                    // Tab bar (container-aligned like search bar)
                    CustomTabBar(selectedTab: $selectedTab)
                        .padding(.top, 2) // pull closer to header
                        .padding(.horizontal)
                    
                    // Content based on selected tab
                    Group {
                        if viewModel.isLoading {
                            ProgressView("Loading places...")
                                .frame(maxWidth: .infinity, minHeight: 300)
                                .foregroundColor(.secondary)
                        } else {
                            ZStack {
                                switch selectedTab {
                                case .list:
                                    PlaceListView(places: viewModel.places, onPlaceTap: { place in
                                        viewModel.presentPlace(place)
                                    }, embeddedInScroll: true)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .leading),
                                            removal: .move(edge: .trailing)
                                        ))
                                case .map:
                                    PlaceMapView(places: viewModel.places)
                                        .frame(height: 500) // Fixed height for map in scroll view
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing),
                                            removal: .move(edge: .leading)
                                        ))
                                }
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingAddPlace) {
                AddPlaceSheet(collectionId: collection.id) { name, address, socialURL, imageData in
                    await viewModel.addPlace(collectionId: collection.id, name: name, address: address, socialURL: socialURL, imageData: imageData)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [shareText])
            }
            .sheet(isPresented: $showingEditMode) {
                EditCollectionSheet(collection: collection) { newName, newDescription, isFavorite in
                    await viewModel.updateCollection(
                        collectionId: collection.id,
                        name: newName,
                        description: newDescription,
                        coverImageUrl: nil,
                        colorTheme: nil,
                        isFavorite: isFavorite,
                        tags: nil
                    )
                }
            }
            .sheet(isPresented: $pendingCoverPicker) {
                ImagePicker(image: $pendingCoverImage)
                    .onDisappear {
                        if let img = pendingCoverImage, let data = img.jpegData(compressionQuality: 0.9) {
                            Task { await viewModel.uploadCollectionCover(collectionId: collection.id, imageData: data) }
                        }
                    }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    let wasDelete = viewModel.didDeleteCollection
                    viewModel.showSuccess = false
                    if wasDelete {
                        NotificationCenter.default.post(
                            name: Notification.Name("CollectionDeleted"),
                            object: nil,
                            userInfo: ["collectionId": collection.id]
                        )
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.successMessage ?? "Done")
            }
            .confirmationDialog(
                "Delete Collection?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteCollection(collectionId: collection.id) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete ‘\(collection.name)’? This action cannot be undone.")
            }
        }
        .task {
            await viewModel.fetchCollectionDetails(collectionId: collection.id)
        }
        .sheet(item: $viewModel.presentedPlace) { presented in
            RemotePlaceDetailView(placeId: presented.remoteId, titleFallback: presented.displayName)
        }
    }
    
    private var collectionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Collection image
            if let imageURL = viewModel.coverImageUrl ?? collection.coverImageUrl {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(LinearGradient(
                            colors: [DesignSystem.Colors.coralHeart.opacity(0.3), DesignSystem.Colors.oceanTeal.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                // Title and places count
                VStack(alignment: .leading, spacing: 6) {
                    Text(collection.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    // Places count directly under title
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(viewModel.places.count) \(viewModel.places.count == 1 ? "place" : "places")")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(DesignSystem.Colors.oceanTeal)
                    .padding(.top, 2)
                    if let description = collection.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8) // Slightly larger gap below "N places"
                    }
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    // Temporarily hidden Add Place button (kept for future use)
                    Button { } label: {
                        Label("Add Place", systemImage: "plus.circle")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(DesignSystem.Colors.coralHeart)
                            )
                            .opacity(0)
                    }
                    .disabled(true)
                    
                    // Temporarily hide share button, keep layout stable
                    Button { } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.oceanTeal)
                            .frame(width: 44, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(DesignSystem.Colors.oceanTeal.opacity(0.1))
                            )
                            .opacity(0)
                    }
                    .disabled(true)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 0) // remove extra gap before segmented control
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Close") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    showingEditMode = true
                } label: {
                    Label("Edit Collection", systemImage: "pencil")
                }
                
                Button {
                    pendingCoverPicker.toggle()
                } label: {
                    Label("Change Cover", systemImage: "photo")
                }

                Button {
                    showingShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Add Place Sheet
struct AddPlaceSheet: View {
    let collectionId: String
    let onSubmit: (String, String, String?, Data?) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var address = ""
    @State private var social = ""
    @State private var pickedImage: UIImage? = nil
    @State private var isPickerPresented = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Address", text: $address)
                    TextField("Social URL (optional)", text: $social)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("Photo (optional)") {
                    Button {
                        isPickerPresented = true
                    } label: {
                        HStack {
                            if let img = pickedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 54, height: 54)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                Image(systemName: "photo")
                                    .frame(width: 54, height: 54)
                                    .foregroundColor(.secondary)
                            }
                            Text(pickedImage == nil ? "Choose Photo" : "Change Photo")
                        }
                    }
                    .sheet(isPresented: $isPickerPresented) {
                        ImagePicker(image: $pickedImage)
                    }
                }
            }
            .navigationTitle("Add Place")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let data = pickedImage?.jpegData(compressionQuality: 0.9)
                            await onSubmit(name, address, social.isEmpty ? nil : social, data)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Minimal UIKit Image Picker Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
                parent.image = img
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

// MARK: - Edit Collection Sheet
struct EditCollectionSheet: View {
    let collection: PlaceCollection
    let onSave: (String?, String?, Bool?) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var isFavorite: Bool
    
    init(collection: PlaceCollection, onSave: @escaping (String?, String?, Bool?) async -> Void) {
        self.collection = collection
        self.onSave = onSave
        _name = State(initialValue: collection.name)
        _description = State(initialValue: collection.description ?? "")
        _isFavorite = State(initialValue: collection.isFavorite)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                }
                Section {
                    Toggle("Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle("Edit Collection")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await onSave(name == collection.name ? nil : name,
                                         description == (collection.description ?? "") ? nil : description,
                                         isFavorite == collection.isFavorite ? nil : isFavorite)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}