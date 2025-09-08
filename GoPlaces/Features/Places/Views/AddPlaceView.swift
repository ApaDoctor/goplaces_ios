//
//  AddPlaceView.swift
//  GoPlaces
//
//  Created by Volodymyr Piskun on 03.09.2025.
//

import SwiftUI
import SwiftData

struct AddPlaceView: View {
    
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var address = ""
    @State private var website = ""
    @State private var phoneNumber = ""
    @State private var rating: Double = 0
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Place Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Address", text: $address)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Website", text: $website)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.phonePad)
                } header: {
                    Text("Place Information")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating: \(rating, specifier: "%.1f")")
                            .font(.subheadline)
                        
                        Slider(value: $rating, in: 0...5, step: 0.1)
                    }
                } header: {
                    Text("Rating (Optional)")
                }
            }
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Save") {
                            Task {
                                await savePlace()
                            }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Methods
    private func savePlace() async {
        isLoading = true
        
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedWebsite = website.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let place = Place(
                name: trimmedName,
                address: trimmedAddress.isEmpty ? "" : trimmedAddress,
                socialURL: "",
                rating: rating > 0 ? rating : 0.0,
                phoneNumber: trimmedPhone.isEmpty ? nil : trimmedPhone,
                website: trimmedWebsite.isEmpty ? nil : trimmedWebsite
            )
            
            modelContext.insert(place)
            try modelContext.save()
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

#Preview {
    let schema = Schema([Place.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    
    return AddPlaceView()
        .modelContainer(container)
}