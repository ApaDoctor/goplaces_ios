//
//  SharedAPIClient.swift
//  Share Extension
//
//  Simplified API client for Share Extension
//  Created by Volodymyr Piskun on 04.09.2025.
//

import Foundation
import SwiftUI
import OSLog

// MARK: - API Models (Share Extension specific)

struct ProcessURLRequest: Codable {
    let url: String
}

struct TaskResponse: Codable {
    let taskId: String
    let status: String
    let quickMetadata: QuickMetadata
    let estimatedCompletionSeconds: Int
    
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status
        case quickMetadata = "quick_metadata"
        case estimatedCompletionSeconds = "estimated_completion_seconds"
    }
    
    var estimatedSeconds: Int? {
        return estimatedCompletionSeconds
    }
    
    var progress: Int? {
        return nil
    }
    
    var stageMessage: String {
        return quickMetadata.stageMessage
    }
}

struct ProcessingStatus: Codable {
    let taskId: String
    let status: String
    let progressPercentage: Int
    let currentStage: String
    let stageMessage: String
    let estimatedCompletionSeconds: Int?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status
        case progressPercentage = "progress_percentage"
        case currentStage = "current_stage"
        case stageMessage = "stage_message"
        case estimatedCompletionSeconds = "estimated_completion_seconds"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var progress: Int? {
        return progressPercentage
    }
    
    var estimatedSeconds: Int? {
        return estimatedCompletionSeconds
    }
}

// Type alias for compatibility
typealias ProcessingStatusResponse = ProcessingStatus

struct QuickMetadata: Codable {
    let statusCode: Int
    let accessible: Bool
    let contentLength: Int
    let pageTitle: String
    let videoTitle: String
    let thumbnailUrl: String
    let redirectUrl: String?
    let quickDescription: String
    
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case accessible
        case contentLength = "content_length"
        case pageTitle = "page_title"
        case videoTitle = "video_title"
        case thumbnailUrl = "thumbnail_url"
        case redirectUrl = "redirect_url"
        case quickDescription = "quick_description"
    }
    
    var stageMessage: String {
        return quickDescription
    }
}

struct ProcessingResult: Codable {
    let url: String
    let platform: String
    let timestamp: Date
    let processingTimeSeconds: Double
    let success: Bool
    let metadata: QuickMetadata
    let caption: String?
    let places: [ExtractedPlace]
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case url
        case platform
        case timestamp
        case processingTimeSeconds = "processing_time_seconds"
        case success
        case metadata
        case caption
        case places
        case error
    }
}

struct ExtractedPlace: Codable {
    let id: String  // Unique identifier from the backend
    let name: String
    let location: String?
    let placeType: String?
    let confidenceScore: Double
    let googlePlaceId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case placeType = "place_type"
        case confidenceScore = "confidence_score"
        case googlePlaceId = "google_place_id"
    }
}

// MARK: - Collection Management Models

struct PlaceCollection: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let coverImageUrl: String?
    let placeCount: Int
    let createdAt: Date
    let updatedAt: Date
    let colorTheme: String?
    let isFavorite: Bool
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case coverImageUrl = "cover_image_url"
        case placeCount = "place_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case colorTheme = "color_theme"
        case isFavorite = "is_favorite"
        case tags
    }
    
    var themeColor: String {
        return colorTheme ?? "coral"
    }
    
    var isRecentlyUpdated: Bool {
        return Date().timeIntervalSince(updatedAt) < 86400
    }
    
    var placeCountText: String {
        return "\(placeCount) place\(placeCount == 1 ? "" : "s")"
    }
}

struct PlaceWithSelection: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let location: String?
    let placeType: String?
    let confidenceScore: Double
    let googlePlaceId: String?
    let categoryColor: String
    let iconName: String? = nil
    let imageUrl: String? = nil
    let confidenceIcon: String? = nil
    let isSelected: Bool? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case placeType = "place_type"
        case confidenceScore = "confidence_score"
        case googlePlaceId = "google_place_id"
        case categoryColor = "category_color"
        case iconName = "icon_name"
        case imageUrl = "image_url"
        case confidenceIcon = "confidence_icon"
        case isSelected = "is_selected"
    }
    
    var displayAddress: String {
        return location ?? "Location unknown"
    }
    
    var displayName: String {
        if confidenceScore > 0.9 {
            return name
        } else if confidenceScore > 0.7 {
            return name
        } else {
            return "\(name)?"
        }
    }
    
    var isHighConfidence: Bool {
        return confidenceScore > 0.8
    }
    
    var color: String {
        return categoryColor
    }
    
    var sfSymbolName: String? {
        return iconName
    }
}

struct CreateCollectionRequest: Codable {
    let name: String
    let description: String?
    let coverImageUrl: String?
    let colorTheme: String?
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case coverImageUrl = "cover_image_url"
        case colorTheme = "color_theme"
        case tags
    }
}

struct AddPlacesToCollectionRequest: Codable {
    let placeIds: [String]
    let collectionIds: [String]
    
    enum CodingKeys: String, CodingKey {
        case placeIds = "place_ids"
        case collectionIds = "collection_ids"
    }
}

struct CollectionOperationResponse: Codable {
    let success: Bool
    let message: String
    let affectedCollections: [String]
    let affectedPlaces: [String]
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case affectedCollections = "affected_collections"
        case affectedPlaces = "affected_places"
    }
}

enum TaskStatus: String, Codable {
    case queued = "queued"
    case processing = "processing"
    case complete = "complete"
    case failed = "failed"
}

struct APIError: Codable, LocalizedError {
    let code: String
    let message: String
    let details: [String: String]?
    
    var errorDescription: String? {
        return message
    }
    
    var localizedDescription: String {
        return message
    }
}

// MARK: - API Client

@MainActor
class APIClient: ObservableObject {
    
    private let baseURL: String = {
        if let env = ProcessInfo.processInfo.environment["API_BASE_URL"], !env.isEmpty {
            return env
        }
        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !fromPlist.isEmpty {
            return fromPlist
        }
        return "https://api-production-b29f.up.railway.app"
    }()
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        // Attach auth header to all requests from the share extension as well
        let token = (ProcessInfo.processInfo.environment["API_TOKEN"] ??
                     (Bundle.main.object(forInfoDictionaryKey: "API_TOKEN") as? String) ??
                     "3b5f7153-cf34-4bdd-85d8-2342ba12a4bc")
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "User-Agent": "GoPlaces-ShareExt/1.0",
            "Authorization": "Bearer \(token)",
            "X-API-Token": token
        ]
        return URLSession(configuration: config)
    }()
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger = Logger(subsystem: "com.goplaces.shareextension", category: "APIClient")
    
    init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = Self.createDateDecodingStrategy()
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    /// Custom date decoding strategy that handles ISO8601 with fractional seconds
    /// Backend sends dates like "2025-09-05T00:35:57.458710Z" with microseconds and Z timezone
    private static func createDateDecodingStrategy() -> JSONDecoder.DateDecodingStrategy {
        return .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Use ISO8601DateFormatter with fractional seconds support
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback without fractional seconds
            let fallbackFormatter = ISO8601DateFormatter()
            fallbackFormatter.formatOptions = [.withInternetDateTime]
            
            if let date = fallbackFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected date string to be ISO8601-formatted."
            )
        }
    }
    
    // MARK: - Main API Method
    
    func extractPlaces(from url: String) async throws -> [Place] {
        logger.info("Starting place extraction for URL: \(url, privacy: .private)")
        
        // Validate URL
        guard !url.isEmpty, url.isValidURL else {
            throw APIError(code: "INVALID_URL", message: "Invalid URL provided", details: nil)
        }
        
        do {
            // Step 1: Start processing task
            let task = try await startProcessing(url: url)
            logger.info("Processing task started: \(task.taskId, privacy: .public)")
            
            // Step 2: Poll for completion
            let result = try await pollForCompletion(taskId: task.taskId)
            logger.info("Processing completed for task: \(task.taskId, privacy: .public)")
            
            // Step 3: Convert to Place models
            let places = result.toPlaceModels(sourceURL: url)
            logger.info("Extracted \(places.count) places from URL")
            
            return places
            
        } catch {
            logger.error("Place extraction failed: \(error.localizedDescription)")
            throw handleNetworkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func startProcessing(url: String) async throws -> TaskResponse {
        let request = ProcessURLRequest(url: url)
        let endpoint = URL(string: "\(baseURL)/process-url")!
        
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Ensure auth headers are explicitly set on the request (in addition to session defaults)
        let token = (ProcessInfo.processInfo.environment["API_TOKEN"] ??
                     (Bundle.main.object(forInfoDictionaryKey: "API_TOKEN") as? String) ??
                     "3b5f7153-cf34-4bdd-85d8-2342ba12a4bc")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(token, forHTTPHeaderField: "X-API-Token")
        urlRequest.httpBody = try encoder.encode(request)
        urlRequest.timeoutInterval = 30.0
        
        // Masked logging for verification
        let tokenPreview = String(token.prefix(6)) + "…"
        logger.debug("POST /process-url with headers: Accept=application/json, Authorization=Bearer (prefix: \(tokenPreview, privacy: .private)), X-API-Token set, baseURL=\(self.baseURL, privacy: .public)")

        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(code: "INVALID_RESPONSE", message: "Invalid response type", details: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? decoder.decode(APIError.self, from: data) {
                throw errorData
            }
            throw APIError(code: "SERVER_ERROR", message: "Server error", details: nil)
        }
        
        return try decoder.decode(TaskResponse.self, from: data)
    }
    
    private func pollForCompletion(taskId: String, maxAttempts: Int = 30) async throws -> ProcessingResult {
        for attempt in 1...maxAttempts {
            logger.debug("Polling attempt \(attempt)/\(maxAttempts) for task: \(taskId, privacy: .public)")
            
            do {
                let status = try await getTaskStatus(taskId)
                
                if status.status == "complete" {
                    logger.info("Task completed: \(taskId, privacy: .public)")
                    return try await getTaskResult(taskId)
                } else if status.status == "failed" {
                    logger.error("Task failed: \(taskId, privacy: .public)")
                    throw APIError(code: "PROCESSING_FAILED", message: "Processing failed: \(status.stageMessage)", details: nil)
                }
                
                // Wait before next poll
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
            } catch {
                if attempt == maxAttempts {
                    throw error
                }
                // Continue polling on non-critical errors
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        
        throw APIError(code: "TIMEOUT", message: "Processing timed out after \(maxAttempts) attempts", details: nil)
    }
    
    func getTaskStatus(_ taskId: String) async throws -> ProcessingStatus {
        let endpoint = URL(string: "\(baseURL)/task/\(taskId)/status")!
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.timeoutInterval = 10.0
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError(code: "STATUS_ERROR", message: "Failed to get task status", details: nil)
        }
        
        return try decoder.decode(ProcessingStatus.self, from: data)
    }
    
    func getTaskResult(_ taskId: String) async throws -> ProcessingResult {
        let endpoint = URL(string: "\(baseURL)/task/\(taskId)/result")!
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.timeoutInterval = 10.0
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError(code: "RESULT_ERROR", message: "Failed to get task result", details: nil)
        }
        
        return try decoder.decode(ProcessingResult.self, from: data)
    }

    /// Get places from a completed task with UI metadata for selection
    func getTaskPlacesForSelection(_ taskId: String) async throws -> [PlaceWithSelection] {
        let endpoint = URL(string: "\(baseURL)/task/\(taskId)/places")!
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.timeoutInterval = 10.0
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(code: "INVALID_RESPONSE", message: "Invalid response", details: nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw APIError(code: "TASK_NOT_FOUND", message: "Task not found", details: nil)
            } else if httpResponse.statusCode == 400 {
                throw APIError(code: "TASK_NOT_COMPLETE", message: "Task not completed yet", details: nil)
            }
            throw APIError(code: "SERVER_ERROR", message: "Server error (\(httpResponse.statusCode))", details: nil)
        }
        
        return try decoder.decode([PlaceWithSelection].self, from: data)
    }
    
    
    // MARK: - Collection Management
    
    /// Get all available collections for the user
    func getAllCollections() async throws -> [PlaceCollection] {
        let endpoint = URL(string: "\(baseURL)/collections")!
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.timeoutInterval = 10.0
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let errorData = try? decoder.decode(APIError.self, from: data) {
                throw errorData
            }
            throw APIError(code: "COLLECTIONS_ERROR", message: "Failed to fetch collections", details: nil)
        }
        
        return try decoder.decode([PlaceCollection].self, from: data)
    }
    
    /// Create a new collection
    func createCollection(name: String, description: String?, coverImageUrl: String?, colorTheme: String?, tags: [String]) async throws -> PlaceCollection {
        let request = CreateCollectionRequest(
            name: name,
            description: description,
            coverImageUrl: coverImageUrl,
            colorTheme: colorTheme,
            tags: tags
        )
        
        let endpoint = URL(string: "\(baseURL)/collections")!
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        urlRequest.timeoutInterval = 15.0
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (httpResponse.statusCode == 201 || httpResponse.statusCode == 200) else {
            if let errorData = try? decoder.decode(APIError.self, from: data) {
                throw errorData
            }
            throw APIError(code: "CREATE_COLLECTION_ERROR", message: "Failed to create collection", details: nil)
        }
        
        return try decoder.decode(PlaceCollection.self, from: data)
    }
    
    /// Add places to selected collections
    func addPlacesToCollections(placeIds: [String], collectionIds: [String]) async throws -> CollectionOperationResponse {
        let request = AddPlacesToCollectionRequest(placeIds: placeIds, collectionIds: collectionIds)
        
        let endpoint = URL(string: "\(baseURL)/collections/add-places")!
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        urlRequest.timeoutInterval = 15.0
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let errorData = try? decoder.decode(APIError.self, from: data) {
                throw errorData
            }
            throw APIError(code: "ADD_PLACES_ERROR", message: "Failed to add places to collections", details: nil)
        }
        
        return try decoder.decode(CollectionOperationResponse.self, from: data)
    }
    
    private func handleNetworkError(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return APIError(code: "NETWORK_UNAVAILABLE", message: "No internet connection available", details: nil)
            case .timedOut:
                return APIError(code: "TIMEOUT", message: "Request timed out", details: nil)
            case .badURL, .unsupportedURL:
                return APIError(code: "INVALID_URL", message: "Invalid URL format", details: nil)
            case .badServerResponse:
                return APIError(code: "INVALID_RESPONSE", message: "Invalid server response", details: nil)
            default:
                return APIError(code: "URL_ERROR", message: urlError.localizedDescription, details: nil)
            }
        }
        
        return APIError(code: "UNKNOWN_ERROR", message: error.localizedDescription, details: nil)
    }
}

// MARK: - Convenience Extensions

extension ProcessingResult {
    /// Convert API extraction result to SwiftData Place models
    func toPlaceModels(sourceURL: String) -> [Place] {
        return places.compactMap { extractedPlace in
            return Place(
                name: extractedPlace.name,
                address: extractedPlace.location ?? "",
                socialURL: sourceURL,
                rating: 0.0, // No rating in new API
                photoURL: metadata.thumbnailUrl.isEmpty ? nil : metadata.thumbnailUrl,
                phoneNumber: nil, // Not provided by new API
                website: nil // Not provided by new API
            )
        }
    }
}

extension ExtractedPlace {
    /// Check if this place has sufficient data to be useful
    var isValid: Bool {
        return !name.isEmpty && confidenceScore > 0.5
    }
    
    /// Get display name for the place
    var displayName: String {
        return name
    }
    
    /// Get display address for the place
    var displayAddress: String {
        return location ?? "Location unknown"
    }
}