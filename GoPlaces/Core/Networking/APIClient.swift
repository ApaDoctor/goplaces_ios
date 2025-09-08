//
//  APIClient.swift
//  GoPlaces
//
//  API client for place extraction with async job polling
//  Created by Volodymyr Piskun on 04.09.2025.
//

import Foundation
import Network
import OSLog

@MainActor
class APIClient: ObservableObject {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger = Logger(subsystem: "com.goplaces.app", category: "APIClient")
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isNetworkAvailable = true
    
    // Active tasks tracking for concurrent request management
    private var activeTasks: [String: ProcessingTask] = [:]
    private let maxConcurrentTasks = APIConfiguration.maxConcurrentRequests
    
    // MARK: - Initialization
    
    init(dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) {
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfiguration.timeout
        config.timeoutIntervalForResource = APIConfiguration.timeout * 2
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: config)
        
        // Configure JSON handling
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = dateDecodingStrategy ?? Self.createDateDecodingStrategy()
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        // Start network monitoring
        setupNetworkMonitoring()
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
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - Public Interface
    
    /// Extract places from a URL with full error handling and retry logic
    func extractPlaces(from url: String) async throws -> [Place] {
        logger.info("Starting place extraction for URL: \(url, privacy: .private)")
        
        // Validate inputs
        guard !url.isEmpty, url.isValidURL else {
            throw APIError.invalidURL
        }
        
        // Check network availability
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        // Check concurrent tasks limit
        try await manageConcurrentTasks()
        
        do {
            // Step 1: Start processing task
            let taskResponse = try await startProcessing(url: url)
            logger.info("Processing task started: \(taskResponse.taskId, privacy: .public)")
            
            // Step 2: Poll for completion
            let result = try await pollForCompletion(taskId: taskResponse.taskId)
            logger.info("Processing completed for task: \(taskResponse.taskId, privacy: .public)")
            
            // Step 3: Convert to Place models
            let places = result.toPlaceModels(sourceURL: url)
            logger.info("Extracted \(places.count) places from URL")
            
            return places
            
        } catch {
            logger.error("Place extraction failed: \(error.localizedDescription)")
            throw handleNetworkError(error)
        }
    }
    
    /// Get status of an active task
    func getTaskStatus(_ taskId: String) async throws -> ProcessingStatus {
        logger.info("Getting status for task: \(taskId, privacy: .public)")
        
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/task/\(taskId)/status")!
        var request = createRequest(url: endpoint, method: "GET")
        
        let (data, response) = try await performRequest(request: &request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw APIError(code: "TASK_NOT_FOUND", message: "Task not found", details: nil)
            }
            throw try decoder.decode(APIError.self, from: data)
        }
        
        return try decoder.decode(ProcessingStatus.self, from: data)
    }
    
    /// Get result of a completed task
    func getTaskResult(_ taskId: String) async throws -> ProcessingResult {
        logger.info("Getting result for task: \(taskId, privacy: .public)")
        
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/task/\(taskId)/result")!
        var request = createRequest(url: endpoint, method: "GET")
        
        let (data, response) = try await performRequest(request: &request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw APIError(code: "TASK_NOT_FOUND", message: "Task not found", details: nil)
            } else if httpResponse.statusCode == 422 {
                throw APIError(code: "TASK_NOT_COMPLETE", message: "Task is not complete yet", details: nil)
            }
            throw try decoder.decode(APIError.self, from: data)
        }
        
        return try decoder.decode(ProcessingResult.self, from: data)
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }
                self.isNetworkAvailable = path.status == .satisfied
                if path.status != .satisfied {
                    self.logger.warning("Network connection lost")
                } else {
                    self.logger.info("Network connection restored")
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    private func manageConcurrentTasks() async throws {
        // Clean up expired tasks
        let now = Date()
        activeTasks = activeTasks.filter { !$0.value.isExpired }
        
        // Check if we're at the limit
        if activeTasks.count >= maxConcurrentTasks {
            logger.warning("Max concurrent tasks reached, waiting for completion")
            
            // Wait for a task to complete (with timeout)
            let maxWaitTime: TimeInterval = 30
            let startTime = now
            
            while activeTasks.count >= maxConcurrentTasks && 
                  Date().timeIntervalSince(startTime) < maxWaitTime {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                activeTasks = activeTasks.filter { !$0.value.isExpired }
            }
            
            if activeTasks.count >= maxConcurrentTasks {
                throw APIError(code: "TOO_MANY_REQUESTS", 
                              message: "Too many concurrent processing requests", 
                              details: nil)
            }
        }
    }
    
    private func startProcessing(url: String) async throws -> TaskResponse {
        let requestBody = ProcessURLRequest(url: url)
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/process-url")!
        
        var urlRequest = createRequest(url: endpoint, method: "POST")
        urlRequest.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await performRequest(request: &urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? decoder.decode(APIError.self, from: data) {
                throw errorData
            }
            throw APIError.serverError
        }
        
        let taskResponse = try decoder.decode(TaskResponse.self, from: data)
        
        // Track the task
        let task = ProcessingTask(
            taskId: taskResponse.taskId,
            url: url,
            startTime: Date(),
            estimatedCompletionSeconds: taskResponse.estimatedCompletionSeconds
        )
        activeTasks[taskResponse.taskId] = task
        
        return taskResponse
    }
    
    private func pollForCompletion(taskId: String, maxAttempts: Int = APIConfiguration.maxPollingAttempts) async throws -> ProcessingResult {
        logger.info("Starting polling for task: \(taskId, privacy: .public)")
        
        for attempt in 1...maxAttempts {
            logger.debug("Polling attempt \(attempt)/\(maxAttempts) for task: \(taskId, privacy: .public)")
            
            do {
                let taskStatus = try await getTaskStatus(taskId)
                
                if taskStatus.status == "complete" {
                    logger.info("Task completed: \(taskId, privacy: .public)")
                    activeTasks.removeValue(forKey: taskId)
                    
                    // Get the final result
                    let result = try await getTaskResult(taskId)
                    return result
                    
                } else if taskStatus.status == "failed" {
                    logger.error("Task failed: \(taskId, privacy: .public)")
                    activeTasks.removeValue(forKey: taskId)
                    
                    throw APIError(code: "PROCESSING_FAILED", 
                                 message: "Processing failed: \(taskStatus.stageMessage)", 
                                 details: ["taskId": taskId])
                    
                } else {
                    logger.debug("Task still processing: \(taskStatus.currentStage) - \(taskStatus.stageMessage)")
                    // Continue polling after delay
                }
                
            } catch {
                // If it's the last attempt, throw the error
                if attempt == maxAttempts {
                    logger.error("Polling failed on final attempt: \(error.localizedDescription)")
                    activeTasks.removeValue(forKey: taskId)
                    throw error
                }
                
                // For other attempts, log and continue
                logger.warning("Polling attempt \(attempt) failed: \(error.localizedDescription)")
            }
            
            // Wait before next poll (with exponential backoff)
            let backoffMultiplier = min(Double(attempt), 3.0) // Cap at 3x
            let delay = APIConfiguration.pollingInterval * backoffMultiplier
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Clean up if we reach here
        activeTasks.removeValue(forKey: taskId)
        
        throw APIError(code: "TIMEOUT", 
                      message: "Processing timed out after \(maxAttempts) attempts", 
                      details: ["taskId": taskId])
    }
    
    private func createRequest(url: URL, method: String) -> Foundation.URLRequest {
        var request = Foundation.URLRequest(url: url)
        request.httpMethod = method
        
        // Add default headers
        for (key, value) in APIConfiguration.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    private func performRequest(request: inout Foundation.URLRequest) async throws -> (Data, URLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            return (data, response)
        } catch {
            // Propagate cancellation without wrapping so callers can ignore it
            if let urlError = error as? URLError, urlError.code == .cancelled {
                throw urlError
            }
            if error is CancellationError {
                throw error
            }
            throw handleNetworkError(error)
        }
    }
    
    // MARK: - Error Handling
    
    func handleNetworkError(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return APIError.networkUnavailable
            case .timedOut:
                return APIError.timeout
            case .badURL, .unsupportedURL:
                return APIError.invalidURL
            case .badServerResponse:
                return APIError.invalidResponse
            default:
                return APIError(
                    code: "URL_ERROR",
                    message: urlError.localizedDescription,
                    details: ["code": String(urlError.code.rawValue)]
                )
            }
        }
        
        if error is DecodingError {
            return APIError(
                code: "DECODING_ERROR",
                message: "Failed to parse server response",
                details: ["error": error.localizedDescription]
            )
        }
        
        return APIError(
            code: "UNKNOWN_ERROR",
            message: error.localizedDescription,
            details: nil
        )
    }
    
    // MARK: - Utility Methods
    
    /// Check if the API service is available
    func checkHealth() async throws -> Bool {
        guard isNetworkAvailable else {
            return false
        }
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/")!
        var request = createRequest(url: endpoint, method: "GET")
        
        do {
            let (_, response) = try await performRequest(request: &request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            logger.warning("Health check failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Get current active tasks count for monitoring
    var activeTasksCount: Int {
        return activeTasks.count
    }
    
    /// Get a funny loading message from the API with optional category filtering
    func getFunnyMessage(category: FunnyMessage.Category? = nil) async throws -> FunnyMessage {
        logger.info("Getting funny message with category: \(category?.rawValue ?? "random", privacy: .public)")
        
        guard isNetworkAvailable else {
            // Return fallback message when network is unavailable
            let fallbackMessage = category?.fallbackMessage ?? "Working on it..."
            return FunnyMessage(
                message: fallbackMessage,
                category: category?.rawValue ?? "random",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        }
        
        // Construct endpoint with optional category parameter
        var urlComponents = URLComponents(string: "\(APIConfiguration.baseURL)/funny-messages")!
        if let category = category {
            urlComponents.queryItems = [URLQueryItem(name: "category", value: category.rawValue)]
        }
        
        guard let endpoint = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = createRequest(url: endpoint, method: "GET")
        
        do {
            let (data, response) = try await performRequest(request: &request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                logger.warning("Funny message API returned non-200 status: \(httpResponse.statusCode)")
                // Return fallback message on API error
                let fallbackMessage = category?.fallbackMessage ?? "Working on it..."
                return FunnyMessage(
                    message: fallbackMessage,
                    category: category?.rawValue ?? "random",
                    timestamp: ISO8601DateFormatter().string(from: Date())
                )
            }
            
            let funnyMessage = try decoder.decode(FunnyMessage.self, from: data)
            logger.debug("Retrieved funny message: \(funnyMessage.message, privacy: .private)")
            
            return funnyMessage
            
        } catch {
            logger.error("Failed to get funny message: \(error.localizedDescription)")
            
            // Return fallback message on any error
            let fallbackMessage = category?.fallbackMessage ?? "Working on it..."
            return FunnyMessage(
                message: fallbackMessage,
                category: category?.rawValue ?? "random",
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        }
    }
    
    /// Cancel all active tasks (for cleanup)
    func cancelAllTasks() {
        let taskCount = activeTasks.count
        logger.info("Cancelling all active tasks (\(taskCount))")
        activeTasks.removeAll()
    }
    
    // MARK: - Collection Management Methods
    
    /// Get all user collections for the collection selection screen
    func getAllCollections() async throws -> [PlaceCollection] {
        logger.info("Getting all collections from API")
        
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/collections")!
        var request = createRequest(url: endpoint, method: "GET")
        
        let (data, response) = try await performRequest(request: &request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            logger.error("Collections API returned status: \(httpResponse.statusCode)")
            throw APIError.serverError
        }
        
        let collections = try decoder.decode([PlaceCollection].self, from: data)
        logger.info("Retrieved \(collections.count) collections")
        
        return collections
    }
    
    /// Create a new collection
    func createCollection(name: String, description: String? = nil, coverImageUrl: String? = nil, colorTheme: String? = nil, tags: [String] = []) async throws -> PlaceCollection {
        logger.info("Creating new collection: \(name)")
        
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        let requestBody = CreateCollectionRequest(
            name: name,
            description: description,
            coverImageUrl: coverImageUrl,
            colorTheme: colorTheme,
            tags: tags
        )
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/collections")!
        var request = createRequest(url: endpoint, method: "POST")
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await performRequest(request: &request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            logger.error("Create collection API returned status: \(httpResponse.statusCode)")
            throw APIError.serverError
        }
        
        let collection = try decoder.decode(PlaceCollection.self, from: data)
        logger.info("Created collection: \(collection.id) - \(collection.name)")
        
        return collection
    }

    /// Get places inside a collection for detail screen
    func getCollectionPlaces(collectionId: String) async throws -> CollectionPlacesResponse {
        logger.info("Getting places for collection: \(collectionId)")
        
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/collections/\(collectionId)/places")!
        var request = createRequest(url: endpoint, method: "GET")
        
        let (data, response) = try await performRequest(request: &request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw APIError(code: "COLLECTION_NOT_FOUND", message: "Collection not found", details: nil)
            }
            logger.error("Collection places API returned status: \(httpResponse.statusCode)")
            throw APIError.serverError
        }
        
        return try decoder.decode(CollectionPlacesResponse.self, from: data)
    }
    
    /// Get places from a completed task with UI metadata for selection
    func getTaskPlacesForSelection(_ taskId: String) async throws -> [PlaceWithSelection] {
        logger.info("Getting places for task: \(taskId) with UI metadata")
        
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/task/\(taskId)/places")!
        var request = createRequest(url: endpoint, method: "GET")
        
        let (data, response) = try await performRequest(request: &request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw APIError(code: "TASK_NOT_FOUND", message: "Task not found", details: nil)
            } else if httpResponse.statusCode == 400 {
                throw APIError(code: "TASK_NOT_COMPLETE", message: "Task not completed yet", details: nil)
            }
            logger.error("Task places API returned status: \(httpResponse.statusCode)")
            throw APIError.serverError
        }
        
        let places = try decoder.decode([PlaceWithSelection].self, from: data)
        logger.info("Retrieved \(places.count) places with UI metadata")
        
        return places
    }
    
    /// Add selected places to collections (final step in share extension flow)
    func addPlacesToCollections(placeIds: [String], collectionIds: [String]) async throws -> CollectionOperationResponse {
        logger.info("Adding \(placeIds.count) places to \(collectionIds.count) collections")
        
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        let requestBody = AddPlacesToCollectionRequest(
            placeIds: placeIds,
            collectionIds: collectionIds
        )
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/collections/add-places")!
        var request = createRequest(url: endpoint, method: "POST")
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await performRequest(request: &request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw APIError(code: "COLLECTIONS_NOT_FOUND", message: "One or more collections not found", details: nil)
            }
            logger.error("Add places to collections API returned status: \(httpResponse.statusCode)")
            throw APIError.serverError
        }
        
        let operationResponse = try decoder.decode(CollectionOperationResponse.self, from: data)
        logger.info("Successfully added places to collections: \(operationResponse.message)")
        
        return operationResponse
    }
    
    /// Update an existing collection
    func updateCollection(_ collectionId: String, request: UpdateCollectionRequest) async throws -> PlaceCollection {
        logger.info("Updating collection: \(collectionId)")
        
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/collections/\(collectionId)")!
        var urlRequest = createRequest(url: endpoint, method: "PUT")
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await performRequest(request: &urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw APIError(code: "COLLECTION_NOT_FOUND", message: "Collection not found", details: nil)
            }
            logger.error("Update collection API returned status: \(httpResponse.statusCode)")
            throw APIError.serverError
        }
        
        let collection = try decoder.decode(PlaceCollection.self, from: data)
        logger.info("Updated collection: \(collection.name)")
        
        return collection
    }

    // MARK: - Place Detail
    /// Fetch rich place detail by backend place id
    func getPlaceDetail(placeId: String) async throws -> PlaceDetailResponse {
        logger.info("Getting place detail for: \(placeId, privacy: .public)")
        
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/places/\(placeId)")!
        var request = createRequest(url: endpoint, method: "GET")
        
        let (data, response) = try await performRequest(request: &request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw APIError(code: "PLACE_NOT_FOUND", message: "Place not found", details: nil)
            }
            logger.error("Place detail API returned status: \(httpResponse.statusCode)")
            throw APIError.serverError
        }
        
        return try decoder.decode(PlaceDetailResponse.self, from: data)
    }
    
    /// Delete a collection
    func deleteCollection(_ collectionId: String) async throws {
        logger.info("Deleting collection: \(collectionId)")
        
        guard isNetworkAvailable else {
            throw APIError.networkUnavailable
        }
        
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/collections/\(collectionId)")!
        var request = createRequest(url: endpoint, method: "DELETE")
        
        let (_, response) = try await performRequest(request: &request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw APIError(code: "COLLECTION_NOT_FOUND", message: "Collection not found", details: nil)
            }
            logger.error("Delete collection API returned status: \(httpResponse.statusCode)")
            throw APIError.serverError
        }
        
        logger.info("Successfully deleted collection")
    }

    // MARK: - Place Creation & Photo Upload
    /// Create a new place in a collection
    func createPlace(in collectionId: String, name: String, address: String = "", socialURL: String? = nil, rating: Double? = nil) async throws -> APIPlace {
        logger.info("Creating place in collection: \(collectionId)")
        
        guard isNetworkAvailable else { throw APIError.networkUnavailable }
        
        let body = CreatePlaceRequest(name: name, address: address, socialURL: socialURL, rating: rating)
        let endpoint = URL(string: "\(APIConfiguration.baseURL)/collections/\(collectionId)/places")!
        var request = createRequest(url: endpoint, method: "POST")
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await performRequest(request: &request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard http.statusCode == 201 || http.statusCode == 200 else { throw APIError.serverError }
        
        return try decoder.decode(APIPlace.self, from: data)
    }
    
    /// Upload a photo for a place (multipart/form-data)
    func uploadPlacePhoto(collectionId: String, placeId: String, imageData: Data, filename: String = "photo.jpg") async throws -> String {
        logger.info("Uploading photo for place: \(placeId)")
        
        guard isNetworkAvailable else { throw APIError.networkUnavailable }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        let url = URL(string: "\(APIConfiguration.baseURL)/collections/\(collectionId)/places/\(placeId)/photo")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        for (k, v) in APIConfiguration.defaultHeaders { if k.lowercased() != "content-type" { req.setValue(v, forHTTPHeaderField: k) } }
        
        var body = Data()
        // file part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        // end boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let (data, response) = try await session.upload(for: req, from: body)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw APIError.serverError }
        
        // parse minimal shape {"photoURL": "..."}
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let urlStr = json["photoURL"] as? String {
            return urlStr
        }
        throw APIError.invalidResponse
    }

    /// Upload/replace a collection cover image (multipart/form-data)
    func uploadCollectionCover(collectionId: String, imageData: Data, filename: String = "cover.jpg") async throws -> String {
        logger.info("Uploading cover for collection: \(collectionId)")
        
        guard isNetworkAvailable else { throw APIError.networkUnavailable }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        let url = URL(string: "\(APIConfiguration.baseURL)/collections/\(collectionId)/cover")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        for (k, v) in APIConfiguration.defaultHeaders { if k.lowercased() != "content-type" { req.setValue(v, forHTTPHeaderField: k) } }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let (data, response) = try await session.upload(for: req, from: body)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw APIError.serverError }
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let urlStr = json["coverImageUrl"] as? String {
            return urlStr
        }
        throw APIError.invalidResponse
    }
}

// MARK: - Network Error Extensions

extension URLError {
    var isNetworkError: Bool {
        switch code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return true
        default:
            return false
        }
    }
    
    var isTimeoutError: Bool {
        switch code {
        case .timedOut, .callIsActive:
            return true
        default:
            return false
        }
    }
}