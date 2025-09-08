//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Volodymyr Piskun on 03.09.2025.
//

import SwiftUI
import UIKit
import Social
import UniformTypeIdentifiers
import SwiftData

// MARK: - Share Extension Data Models

struct ShareExtensionSaveResult {
    let addedPlaces: Int
    let duplicatePlaces: Int
    let totalProcessed: Int
    let errors: [String]
    
    var hasErrors: Bool {
        !errors.isEmpty
    }
}

@objc(ShareExtensionViewController)
class ShareExtensionViewController: UIViewController {
    var hostingController: UIHostingController<AnyView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the extension context for the SwiftUI view
        ExtensionContextManager.shared.extensionContext = self.extensionContext
        
        // Create ModelContainer with fallback mechanism
        let modelContainer = createModelContainer()
        
        // Create SwiftUI view and add it to the view controller
        let shareView = ShareExtensionView()
            .modelContainer(modelContainer)
        
        let hostingController = UIHostingController(rootView: AnyView(shareView))
        self.hostingController = hostingController
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set preferred content size for compact presentation - reduced by 15%
        self.preferredContentSize = CGSize(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.height * 0.70)
    }
    
    private func createModelContainer() -> ModelContainer {
        let schema = Schema([Place.self])
        
        // Use default container for development
        do {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            print("Share Extension: Using default container")
            return container
        } catch {
            print("Share Extension: Failed to create default container: \(error), using memory-only")
            
            // Last resort: in-memory container
            let memoryConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            
            do {
                return try ModelContainer(for: schema, configurations: [memoryConfiguration])
            } catch {
                fatalError("Could not create any ModelContainer for Share Extension: \(error)")
            }
        }
    }
}

struct ShareExtensionView: View {
    @State private var extractedURL: String = ""
    @State private var isLoading = false
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var progressMessage = "Processing URL..."
    @State private var extractedPlaces: [Place] = []
    @State private var processingStep: ProcessingStep = .extractingURL
    @State private var saveResult: ShareExtensionSaveResult?
    @State private var showSuccess = false
    @State private var currentTaskId: String?
    @State private var pollingTimer: Timer?
    @Environment(\.modelContext) private var modelContext
    @StateObject private var apiClient = APIClient()
    @StateObject private var shareExtensionDataManager = ShareExtensionDataManager()
    @StateObject private var loadingState = ShareExtensionLoadingManager()
    
    enum ProcessingStep {
        case extractingURL
        case processingURL
        case selectingPlaces
        case savingPlaces
        case completed
    }
    
    private func completeExtension() {
        if let extensionContext = ExtensionContextManager.shared.extensionContext {
            extensionContext.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
    
    private func cancelExtension() {
        if let extensionContext = ExtensionContextManager.shared.extensionContext {
            let error = NSError(domain: "ShareExtensionErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "User cancelled"])
            extensionContext.cancelRequest(withError: error)
        }
    }
    
    var body: some View {
        // ⚠️ CRITICAL WARNING: DO NOT ADD NavigationView HERE! ⚠️
        // iOS Share Extensions AUTOMATICALLY provide their own navigation container.
        // Adding NavigationView causes DUPLICATE HEADERS which looks unprofessional.
        // This is a SHARE EXTENSION, not a regular app - iOS handles the navigation chrome!
        // If you see duplicate "GoPlaces" headers, it's because someone ignored this warning.
        Group {
                switch processingStep {
                case .extractingURL:
                    ShareExtensionLoadingView(
                        title: loadingState.title,
                        stageMessage: loadingState.stageMessage,
                        progress: nil,
                        showProgress: false
                    )
                    
                case .processingURL:
                    ShareExtensionLoadingView(
                        title: loadingState.title,
                        stageMessage: loadingState.stageMessage,
                        progress: loadingState.progress,
                        showProgress: true
                    )
                    
                case .selectingPlaces:
                    if let taskId = currentTaskId {
                        PremiumShareSelectionView(
                            taskId: taskId,
                            onSave: { selectedPlaceIds, selectedCollectionIds in
                                Task {
                                    await saveToCollections(placeIds: selectedPlaceIds, collectionIds: selectedCollectionIds)
                                }
                            },
                            onCancel: {
                                cancelExtension()
                            }
                        )
                    } else {
                        // Fallback for missing task ID
                        ShareExtensionLoadingView(
                            title: loadingState.title,
                            stageMessage: loadingState.stageMessage,
                            progress: nil,
                            showProgress: false
                        )
                    }
                    
                case .savingPlaces:
                    ShareExtensionLoadingView(
                        title: loadingState.title,
                        stageMessage: loadingState.stageMessage,
                        progress: loadingState.progress,
                        showProgress: true
                    )
                    
                case .completed:
                    if let result = saveResult {
                        SuccessView(result: result) {
                            completeExtension()
                        }
                    } else {
                        ShareExtensionLoadingView(
                            title: loadingState.title,
                            stageMessage: loadingState.stageMessage,
                            progress: 100,
                            showProgress: true
                        )
                    }
                }
                
                if showError && !errorMessage.isEmpty {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ErrorOverlay(message: errorMessage) {
                                retryProcess()
                            }
                        }
                }
            }
            // Navigation modifiers removed - iOS provides the chrome automatically
            // DO NOT add .navigationTitle, .toolbar, or wrap in NavigationView
        .onAppear {
            startProcess()
        }
        .onDisappear {
            stopPolling()
        }
    }
    
    private func startProcess() {
        processingStep = .extractingURL
        loadingState.startLoading(title: "Processing share")
        extractURL()
    }
    
    private func retryProcess() {
        showError = false
        errorMessage = ""
        extractedPlaces = []
        saveResult = nil
        currentTaskId = nil
        stopPolling()
        loadingState.reset()
        startProcess()
    }
    
    private func extractURL() {
        guard let extensionContext = ExtensionContextManager.shared.extensionContext else {
            showError(message: "Unable to access extension context")
            return
        }
        
        ExtensionContextManager.shared.extractURL(from: extensionContext) { url in
            DispatchQueue.main.async {
                if let url = url {
                    self.extractedURL = url
                    self.processURL()
                } else {
                    self.showError(message: "No valid URL found in shared content")
                }
            }
        }
    }
    
    private func processURL() {
        guard !extractedURL.isEmpty else {
            showError(message: "No URL to process")
            return
        }
        
        guard extractedURL.isValidURL else {
            showError(message: "Invalid URL format")
            return
        }
        
        processingStep = .processingURL
        loadingState.startLoading(title: "Processing content")
        
        Task {
            do {
                let cleanedURL = extractedURL.cleanedURL
                
                // Step 1: Start processing and get task ID
                let taskResponse = try await startProcessingTask(url: cleanedURL)
                await MainActor.run {
                    self.currentTaskId = taskResponse.taskId
                    self.loadingState.updateFromTaskResponse(taskResponse)
                }
                
                // Step 2: Start polling for completion
                startPolling()
                
            } catch {
                await MainActor.run {
                    self.handleProcessingError(error)
                }
            }
        }
    }
    
    private func startProcessingTask(url: String) async throws -> TaskResponse {
        let requestBody = ProcessURLRequest(url: url)
        let baseURL = (ProcessInfo.processInfo.environment["API_BASE_URL"]) ?? (Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String) ?? "https://api-production-b29f.up.railway.app"
        let endpoint = URL(string: "\(baseURL)/process-url")!
        
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Ensure Authorization token is passed like in APIClient
        let token = (ProcessInfo.processInfo.environment["API_TOKEN"] ??
                     (Bundle.main.object(forInfoDictionaryKey: "API_TOKEN") as? String) ??
                     "3b5f7153-cf34-4bdd-85d8-2342ba12a4bc")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(token, forHTTPHeaderField: "X-API-Token")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        urlRequest.httpBody = try encoder.encode(requestBody)
        urlRequest.timeoutInterval = 30.0
        
        // Masked logging for verification
        let tokenPreview = String(token.prefix(6)) + "…"
        print("[ShareExt] POST /process-url headers: Accept=application/json, Authorization=Bearer (prefix: \(tokenPreview)), X-API-Token set, baseURL=\(baseURL)")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError(code: "SERVER_ERROR", message: "Server error", details: nil)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TaskResponse.self, from: data)
    }
    
    private func startPolling() {
        guard let taskId = currentTaskId else { return }
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await self.pollTaskStatus(taskId: taskId)
            }
        }
    }
    
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    private func pollTaskStatus(taskId: String) async {
        do {
            let status = try await apiClient.getTaskStatus(taskId)
            
            await MainActor.run {
                self.loadingState.updateFromProcessingStatus(status)
                
                if status.status == "complete" {
                    self.handleTaskCompletion(taskId: taskId)
                } else if status.status == "failed" {
                    self.stopPolling()
                    self.showError(message: "Processing failed: \(status.stageMessage)")
                }
            }
            
        } catch {
            await MainActor.run {
                // Continue polling unless it's a critical error
                if let apiError = error as? APIError, apiError.code == "NETWORK_UNAVAILABLE" {
                    self.stopPolling()
                    self.showError(message: "Network connection lost")
                }
            }
        }
    }
    
    private func handleTaskCompletion(taskId: String) {
        stopPolling()
        
        Task {
            do {
                let result = try await apiClient.getTaskResult(taskId)
                let places = result.toPlaceModels(sourceURL: extractedURL)
                
                await MainActor.run {
                    if places.isEmpty {
                        self.showError(message: "No places found in the shared content. Please try a different URL.")
                    } else {
                        self.extractedPlaces = places
                        self.processingStep = .selectingPlaces
                        self.loadingState.stopLoading()
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.handleProcessingError(error)
                }
            }
        }
    }
    
    private func handleProcessingError(_ error: Error) {
        let errorMsg: String
        if let apiError = error as? APIError {
            switch apiError.code {
            case "NETWORK_UNAVAILABLE":
                errorMsg = "No internet connection. Please check your network and try again."
            case "TIMEOUT":
                errorMsg = "Request timed out. The server may be busy, please try again."
            case "INVALID_URL":
                errorMsg = "The shared URL is not valid. Please try sharing a different link."
            case "NO_RESULTS":
                errorMsg = "No places found in this content. Try sharing a post with location tags."
            default:
                errorMsg = "Failed to extract places: \(apiError.message)"
            }
        } else {
            errorMsg = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        self.stopPolling()
        self.showError(message: errorMsg)
    }
    
    private func savePlaces(_ places: [Place]) async {
        processingStep = .savingPlaces
        progressMessage = "Saving places..."
        
        await MainActor.run {
            shareExtensionDataManager.savePlaces(places, in: modelContext) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let saveResult):
                        self.saveResult = saveResult
                        self.processingStep = .completed
                        self.showSuccess = true
                        
                        // Add haptic feedback for success
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.success)
                        
                        // Auto-complete after showing success briefly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.completeExtension()
                        }
                        
                    case .failure(let error):
                        self.progressMessage = "Processing URL..."
                        self.processingStep = .selectingPlaces
                        let errorMessage = "Failed to save places: \(error.localizedDescription)"
                        self.showError(message: errorMessage)
                        
                        // Add haptic feedback for error
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.error)
                    }
                }
            }
        }
    }
    
    private func saveToCollections(placeIds: [String], collectionIds: [String]) async {
        processingStep = .savingPlaces
        loadingState.title = "Saving places"
        loadingState.stageMessage = "Adding to your collections"
        loadingState.progress = 90
        
        do {
            _ = try await apiClient.addPlacesToCollections(
                placeIds: placeIds, 
                collectionIds: collectionIds
            )
            
            await MainActor.run {
                // Create a result summary for success display
                let saveResult = ShareExtensionSaveResult(
                    addedPlaces: placeIds.count,
                    duplicatePlaces: 0, // Collections API doesn't track duplicates
                    totalProcessed: placeIds.count,
                    errors: []
                )
                
                self.saveResult = saveResult
                self.processingStep = .completed
                self.showSuccess = true
                
                // Add haptic feedback for success
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
                
                // Do not attempt to open the main app from a share extension to avoid RBS assertion errors
            }
            
        } catch {
            await MainActor.run {
                self.processingStep = .selectingPlaces
                let errorMessage = "Failed to save to collections: \(error.localizedDescription)"
                self.showError(message: errorMessage)
                
                // Add haptic feedback for error
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
            }
        }
    }
    
    private func generatePlaceName(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return "New Place"
        }
        
        // Extract a friendly name from the domain
        let components = host.components(separatedBy: ".")
        if let domain = components.first(where: { !["www", "m", "mobile"].contains($0) }) {
            return "\(domain.capitalized) Place"
        }
        
        return "New Place"
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Share Extension Data Manager

@MainActor
class ShareExtensionDataManager: ObservableObject {
    
    func savePlaces(_ places: [Place], in modelContext: ModelContext, completion: @escaping (Result<ShareExtensionSaveResult, Error>) -> Void) {
        var addedCount = 0
        var duplicateCount = 0
        var errors: [String] = []
        
        for place in places {
            do {
                // Check if place already exists
                let cleanedURL = place.socialURL.cleanedURL
                let predicate = #Predicate<Place> { existingPlace in
                    existingPlace.socialURL == cleanedURL
                }
                
                let descriptor = FetchDescriptor<Place>(predicate: predicate)
                let existingPlaces = try modelContext.fetch(descriptor)
                
                if !existingPlaces.isEmpty {
                    duplicateCount += 1
                    continue
                }
                
                // Save new place
                modelContext.insert(place)
                addedCount += 1
                
            } catch {
                errors.append("Failed to save '\(place.name)': \(error.localizedDescription)")
            }
        }
        
        // Save the context
        do {
            if addedCount > 0 {
                try modelContext.save()
            }
            
            let result = ShareExtensionSaveResult(
                addedPlaces: addedCount,
                duplicatePlaces: duplicateCount,
                totalProcessed: places.count,
                errors: errors
            )
            
            completion(.success(result))
            
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - Extension Context Manager
class ExtensionContextManager: ObservableObject {
    static let shared = ExtensionContextManager()
    weak var extensionContext: NSExtensionContext?
    
    private init() {}
    
    func extractURL(from extensionContext: NSExtensionContext, completion: @escaping (String?) -> Void) {
        guard let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            completion(nil)
            return
        }
        
        var foundURL: String?
        let group = DispatchGroup()
        
        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else { continue }
            
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error loading URL: \(error.localizedDescription)")
                            return
                        }
                        
                        if let url = item as? URL, self.isValidShareURL(url.absoluteString) {
                            foundURL = url.absoluteString
                        }
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    group.enter()
                    attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error loading text: \(error.localizedDescription)")
                            return
                        }
                        
                        if let text = item as? String {
                            // Try to extract URL from text
                            if let extractedURL = self.extractURLFromText(text), self.isValidShareURL(extractedURL) {
                                foundURL = extractedURL
                            }
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(foundURL)
        }
    }
    
    private func isValidShareURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        
        // Basic validation
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return false
        }
        
        // Check for valid host
        guard let host = url.host, !host.isEmpty else {
            return false
        }
        
        // Sanitize the URL string
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedURL.count <= 2048 else { return false } // Reasonable URL length limit
        
        return true
    }
    
    private func extractURLFromText(_ text: String) -> String? {
        // Simple URL extraction from text using regex
        let pattern = #"https?://[^\s<>\"'{}|\\^`\[\]]+"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: text.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let urlRange = Range(match.range, in: text)
            if let urlRange = urlRange {
                return String(text[urlRange])
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Views

struct SuccessView: View {
    let result: ShareExtensionSaveResult
    let onComplete: () -> Void
    private let showOpenAppButton = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success icon - coral with teal accent ring
            ZStack {
                Circle()
                    .fill(Color.oceanTeal.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.coralHeart)
            }
            
            // Success message
            VStack(spacing: 8) {
                Text("Success!")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color.deepNavy)
                
                Text(successMessage)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Details if available
            if result.addedPlaces > 0 || result.duplicatePlaces > 0 {
                VStack(spacing: 8) {
                    if result.addedPlaces > 0 {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.coralHeart)
                            Text("\(result.addedPlaces) place\(result.addedPlaces == 1 ? "" : "s") added to your collections")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.deepNavy)
                        }
                    }
                    
                    if result.duplicatePlaces > 0 {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(Color.oceanTeal)
                            Text("\(result.duplicatePlaces) duplicate\(result.duplicatePlaces == 1 ? "" : "s") skipped")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.deepNavy.opacity(0.7))
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                // Open GoPlaces App button (hidden via flag; kept for future use)
                if showOpenAppButton {
                    Button {
                        openMainApp()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.forward.app")
                            Text("Open GoPlaces App")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.coralHeart)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Done button - secondary teal outline
                Button {
                    onComplete()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.oceanTeal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.oceanTeal.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.oceanTeal, lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.white)
    }
    
    private func openMainApp() {
        // Correct sequence for extensions: complete first, then open URL in completion handler
        guard let extContext = ExtensionContextManager.shared.extensionContext else { return }
        let primaryURL = URL(string: "goplaces://collections")
        let fallbackURL = URL(string: "goplaces://")
        
        extContext.completeRequest(returningItems: nil) { _ in
            if let primaryURL = primaryURL {
                extContext.open(primaryURL) { success in
                    if !success, let fallbackURL = fallbackURL {
                        extContext.open(fallbackURL, completionHandler: nil)
                    }
                }
            } else if let fallbackURL = fallbackURL {
                extContext.open(fallbackURL, completionHandler: nil)
            }
        }
    }
    
    private var successMessage: String {
        if result.addedPlaces > 0 && result.duplicatePlaces > 0 {
            return "Saved \(result.addedPlaces) new place\(result.addedPlaces == 1 ? "" : "s"), \(result.duplicatePlaces) already existed"
        } else if result.addedPlaces > 0 {
            return "Saved \(result.addedPlaces) place\(result.addedPlaces == 1 ? "" : "s") to your collection"
        } else if result.duplicatePlaces > 0 {
            return "All \(result.duplicatePlaces) place\(result.duplicatePlaces == 1 ? "" : "s") already in your collection"
        } else {
            return "Places processed successfully"
        }
    }
}

struct ErrorOverlay: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.system(size: 22, weight: .medium))
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 40)
    }
}

#Preview {
    let schema = Schema([Place.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    
    return ShareExtensionView()
        .modelContainer(container)
}
