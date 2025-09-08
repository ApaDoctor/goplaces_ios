//
//  LoadingTestView.swift
//  GoPlaces
//
//  Test view to showcase premium loading components
//  Created by Volodymyr Piskun on 05.09.2025.
//

import SwiftUI

struct LoadingTestView: View {
    @State private var showProgressLoading = false
    @State private var showSpinnerLoading = false
    @State private var showCompactLoading = false
    @State private var progress: Double = 25
    @State private var stageMessage = "🤖 AI is analyzing your content for travel insights..."
    @State private var estimatedSeconds = 30
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Test Section Header
                    VStack {
                        Text("Premium Loading Components")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Testing the new black-themed loading designs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    Divider()
                    
                    // Controls Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Controls")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Progress: \(Int(progress))%")
                                    .font(.caption)
                                Spacer()
                                Slider(value: $progress, in: 0...100, step: 5)
                                    .frame(width: 120)
                            }
                            
                            HStack {
                                Text("Est. Time: \(estimatedSeconds)s")
                                    .font(.caption)
                                Spacer()
                                Slider(value: .init(
                                    get: { Double(estimatedSeconds) },
                                    set: { estimatedSeconds = Int($0) }
                                ), in: 5...120, step: 5)
                                    .frame(width: 120)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stage Message:")
                                    .font(.caption)
                                TextField("Stage message", text: $stageMessage)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                            }
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button("Progress Loading") {
                                showProgressLoading = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            Button("Spinner Loading") {
                                showSpinnerLoading = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("Compact Loading") {
                                showCompactLoading = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Divider()
                    
                    // Live Preview Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Live Preview")
                            .font(.headline)
                        
                        // Progress Loading Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("With Progress")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            PremiumLoadingView(
                                title: "Processing your content...",
                                subtitle: stageMessage,
                                progress: progress,
                                estimatedSeconds: estimatedSeconds
                            )
                            .frame(height: 200)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Spinner Loading Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Spinner Only")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            PremiumLoadingView(
                                title: "Finding places in your content...",
                                subtitle: stageMessage,
                                estimatedSeconds: estimatedSeconds
                            )
                            .frame(height: 200)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Compact Loading Preview
                        Group {
                            Text("Compact Style")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            CompactLoadingView(
                                message: "Saving places to collection...",
                                progress: progress
                            )
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Progress Bar Preview
                        Group {
                            Text("Progress Bar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 12) {
                                // LoadingProgressBar components removed - not implemented yet
                                Text("Progress bars will be implemented here")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Loading Tests")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showProgressLoading) {
            fullScreenLoadingDemo(title: "Processing Instagram Post", withProgress: true)
        }
        .sheet(isPresented: $showSpinnerLoading) {
            fullScreenLoadingDemo(title: "Extracting Places", withProgress: false)
        }
        .sheet(isPresented: $showCompactLoading) {
            compactLoadingDemo()
        }
    }
    
    private func fullScreenLoadingDemo(title: String, withProgress: Bool) -> some View {
        NavigationView {
            PremiumLoadingView(
                title: title,
                subtitle: stageMessage
            )
            .navigationTitle("Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showProgressLoading = false
                        showSpinnerLoading = false
                    }
                }
            }
        }
    }
    
    private func compactLoadingDemo() -> some View {
        NavigationView {
            VStack(spacing: 32) {
                CompactLoadingView(
                    message: "Processing your request...",
                    progress: progress
                )
                
                CompactLoadingView(
                    message: "Saving to collection...",
                    progress: nil
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Compact Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showCompactLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    LoadingTestView()
}