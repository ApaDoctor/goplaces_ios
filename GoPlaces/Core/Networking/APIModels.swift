//
//  APIModels.swift
//  GoPlaces
//
//  API models for place extraction and job management
//  Created by Volodymyr Piskun on 04.09.2025.
//

import Foundation

// MARK: - Request Models

struct ProcessURLRequest: Codable {
    let url: String
}

// MARK: - Funny Message Models

struct FunnyMessage: Codable, Hashable {
    let message: String
    let category: String
    let timestamp: String
    
    // Category-based message types for better UX
    enum Category: String, CaseIterable {
        case processing = "processing"
        case extraction = "extraction"  
        case analysis = "analysis"
        case random = "random"
        
        var fallbackMessage: String {
            switch self {
            case .processing:
                return "Processing your content..."
            case .extraction:
                return "Extracting content details..."
            case .analysis:
                return "Analyzing with AI..."
            case .random:
                return "Working on it..."
            }
        }
    }
    
    /// Get the category as a typed enum
    var categoryEnum: Category {
        return Category(rawValue: category) ?? .random
    }
    
    /// Check if message is recent (within last 5 minutes)
    var isRecent: Bool {
        guard let messageDate = ISO8601DateFormatter().date(from: timestamp) else {
            return false
        }
        return Date().timeIntervalSince(messageDate) < 300 // 5 minutes
    }
}

// MARK: - Response Models

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
}

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
    let name: String
    let location: String?
    let placeType: String?
    let confidenceScore: Double
    let googlePlaceId: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case location
        case placeType = "place_type"
        case confidenceScore = "confidence_score"
        case googlePlaceId = "google_place_id"
    }
}

enum TaskStatus: String, Codable {
    case queued = "queued"
    case processing = "processing"
    case complete = "complete"
    case failed = "failed"
}

// MARK: - Error Models

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
    
    // Common API error codes
    static let invalidResponse = APIError(code: "INVALID_RESPONSE", message: "Invalid response from server", details: nil)
    static let networkUnavailable = APIError(code: "NETWORK_UNAVAILABLE", message: "Network connection unavailable", details: nil)
    static let timeout = APIError(code: "TIMEOUT", message: "Request timed out", details: nil)
    static let serverError = APIError(code: "SERVER_ERROR", message: "Internal server error", details: nil)
    static let invalidURL = APIError(code: "INVALID_URL", message: "Invalid URL provided", details: nil)
    static let extractionFailed = APIError(code: "EXTRACTION_FAILED", message: "Place extraction failed", details: nil)
    static let noResults = APIError(code: "NO_RESULTS", message: "No places found in content", details: nil)
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
    
    /// Get the theme color for UI styling
    var themeColor: String {
        return colorTheme ?? "coral"
    }
    
    /// Check if this collection is recently updated (within 24 hours)
    var isRecentlyUpdated: Bool {
        return Date().timeIntervalSince(updatedAt) < 86400 // 24 hours
    }
    
    /// Display text for place count
    var placeCountText: String {
        return "\(placeCount) place\(placeCount == 1 ? "" : "s")"
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

struct UpdateCollectionRequest: Codable {
    let name: String?
    let description: String?
    let coverImageUrl: String?
    let colorTheme: String?
    let isFavorite: Bool?
    let tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case coverImageUrl = "cover_image_url"
        case colorTheme = "color_theme"
        case isFavorite = "is_favorite"
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

struct PlaceWithSelection: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let location: String?
    let placeType: String?
    let confidenceScore: Double
    let googlePlaceId: String?
    let categoryColor: String
    let iconName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case placeType = "place_type"
        case confidenceScore = "confidence_score"
        case googlePlaceId = "google_place_id"
        case categoryColor = "category_color"
        case iconName = "icon_name"
    }
    
    /// Display address for the place
    var displayAddress: String {
        return location ?? "Location unknown"
    }
    
    /// Display name with confidence indicator for high-confidence places
    var displayName: String {
        if confidenceScore > 0.9 {
            return name
        } else if confidenceScore > 0.7 {
            return name
        } else {
            return "\(name)?"  // Add question mark for low confidence
        }
    }
    
    /// Check if place has high confidence score
    var isHighConfidence: Bool {
        return confidenceScore > 0.8
    }
    
    /// Get color as SwiftUI Color (requires Color extension)
    var color: String {
        return categoryColor
    }
    
    /// Get SF Symbol name for the icon
    var sfSymbolName: String {
        return iconName
    }
}

// MARK: - Place Detail

struct PlaceDetailResponse: Codable {
    let id: String
    let name: String
    let address: String
    let rating: Double?
    let reviewCount: Int?
    let priceLevel: Int?
    let averageCost: String?
    let description: String
    let openingHours: [String: String]?
    let website: String?
    let phoneNumber: String?
    let photoUrls: [String]
    let thumbnails: [String]
    let status: String?
    let closingTime: String?
    let socialUrl: String?
    let googlePlaceId: String?
    let googleMapsUrl: String?
    let googleMapsAppUrl: String?
    let coordinates: Coordinates?
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, rating, description, status
        case reviewCount = "review_count"
        case priceLevel = "price_level"
        case averageCost = "average_cost"
        case openingHours = "opening_hours"
        case website
        case phoneNumber = "phone_number"
        case photoUrls = "photo_urls"
        case thumbnails
        case closingTime = "closing_time"
        case socialUrl = "social_url"
        case googlePlaceId = "google_place_id"
        case googleMapsUrl = "google_maps_url"
        case googleMapsAppUrl = "google_maps_app_url"
        case coordinates
    }
}

struct Coordinates: Codable {
    let lat: Double
    let lng: Double
}

// MARK: - Collections: Places in Collection Response

struct CollectionPlacesResponse: Codable {
    let collection: PlaceCollection
    let places: [APIPlace]
    let shareLink: String
}

struct APIPlace: Codable {
    let id: String
    let name: String
    let address: String
    let socialURL: String?
    let rating: Double?
    let photoURL: String?
    let addedDate: String?
}

extension APIPlace {
    func toPlace() -> Place {
        Place(
            name: name,
            address: address,
            socialURL: socialURL ?? "",
            rating: rating ?? 0.0,
            photoURL: photoURL
        )
    }
}

// MARK: - Create Place Request

struct CreatePlaceRequest: Codable {
    let name: String
    let address: String
    let socialURL: String?
    let rating: Double?
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

// MARK: - Network Configuration

struct APIConfiguration {
    static let baseURL: String = {
        if let env = ProcessInfo.processInfo.environment["API_BASE_URL"], !env.isEmpty {
            return env
        }
        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !fromPlist.isEmpty {
            return fromPlist
        }
        return "https://api-production-b29f.up.railway.app"
    }()
    /// Hardcoded token for test deployments; optionally override via Info.plist (API_TOKEN) or env
    static let apiToken: String = {
        if let env = ProcessInfo.processInfo.environment["API_TOKEN"], !env.isEmpty {
            return env
        }
        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "API_TOKEN") as? String, !fromPlist.isEmpty {
            return fromPlist
        }
        // Hardcoded fallback used for internal testing
        return "3b5f7153-cf34-4bdd-85d8-2342ba12a4bc"
    }()
    static let timeout: TimeInterval = 30.0
    static let maxPollingAttempts = 50
    static let pollingInterval: TimeInterval = 2.0
    static let maxConcurrentRequests = 3
    
    // Request headers
    static var defaultHeaders: [String: String] {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "GoPlaces-iOS/1.0",
            // Send token in Authorization header; backend also supports X-API-Token
            "Authorization": "Bearer \(apiToken)",
            "X-API-Token": apiToken
        ]
    }
}

// MARK: - Job Management

/// Represents an active processing task
struct ProcessingTask {
    let taskId: String
    let url: String
    let startTime: Date
    let estimatedCompletionSeconds: Int
    
    var isExpired: Bool {
        let expectedCompletion = startTime.addingTimeInterval(TimeInterval(estimatedCompletionSeconds))
        return Date() > expectedCompletion.addingTimeInterval(30) // 30 second buffer
    }
    
    var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
}