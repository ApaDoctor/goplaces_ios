//
//  FunnyMessageService.swift
//  GoPlaces
//
//  Manages funny loading messages with caching and rotation
//  Created by Volodymyr Piskun on 05.09.2025.
//

import Foundation
import OSLog

/// Service for managing funny loading messages with intelligent caching and rotation
@MainActor
class FunnyMessageService: ObservableObject {
    
    // MARK: - Properties
    
    private let apiClient: APIClient
    private let logger = Logger(subsystem: "com.goplaces.app", category: "FunnyMessageService")
    
    // Message cache organized by category
    private var messageCache: [FunnyMessage.Category: [FunnyMessage]] = [:]
    private var cacheTimestamps: [FunnyMessage.Category: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    private let messageCacheSize = 8 // Cache 8 messages per category
    
    // Message rotation state
    private var currentMessageIndices: [FunnyMessage.Category: Int] = [:]
    private var lastMessageRequestTime: Date = Date.distantPast
    private let messageRotationInterval: TimeInterval = 12.0 // Rotate every 12 seconds for readability
    
    // Loading state
    @Published private(set) var isLoadingMessages = false
    
    // MARK: - Initialization
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
        
        // Initialize rotation indices
        for category in FunnyMessage.Category.allCases {
            currentMessageIndices[category] = 0
        }
        
        logger.info("FunnyMessageService initialized")
    }
    
    // MARK: - Public Interface
    
    /// Get a funny message for the specified category with smart caching and rotation
    func getMessage(for category: FunnyMessage.Category) async -> FunnyMessage {
        logger.debug("Getting message for category: \(category.rawValue, privacy: .public)")
        
        // Check if we have valid cached messages
        if let cachedMessages = getCachedMessages(for: category), !cachedMessages.isEmpty {
            let rotatedMessage = getRotatedMessage(from: cachedMessages, for: category)
            logger.debug("Returning cached rotated message: \(rotatedMessage.message, privacy: .private)")
            return rotatedMessage
        }
        
        // No valid cache, fetch new messages in background
        await refreshMessagesForCategory(category)
        
        // Return cached message if available, otherwise fallback
        if let cachedMessages = messageCache[category], !cachedMessages.isEmpty {
            return getRotatedMessage(from: cachedMessages, for: category)
        }
        
        // Ultimate fallback
        return createFallbackMessage(for: category)
    }
    
    /// Pre-warm the cache with messages for all categories (call at app launch)
    func preWarmCache() async {
        logger.info("Pre-warming message cache for all categories")
        
        // Fetch messages for all categories concurrently
        await withTaskGroup(of: Void.self) { group in
            for category in FunnyMessage.Category.allCases {
                group.addTask { [weak self] in
                    await self?.refreshMessagesForCategory(category)
                }
            }
        }
        
        logger.info("Cache pre-warming completed")
    }
    
    /// Clear all cached messages (useful for testing or manual refresh)
    func clearCache() {
        messageCache.removeAll()
        cacheTimestamps.removeAll()
        currentMessageIndices = currentMessageIndices.mapValues { _ in 0 }
        logger.info("Message cache cleared")
    }
    
    /// Get cache status for monitoring
    var cacheStatus: [FunnyMessage.Category: Int] {
        return messageCache.mapValues { $0.count }
    }
    
    // MARK: - Private Methods
    
    private func getCachedMessages(for category: FunnyMessage.Category) -> [FunnyMessage]? {
        // Check if cache is still valid
        guard let timestamp = cacheTimestamps[category],
              Date().timeIntervalSince(timestamp) < cacheValidityDuration else {
            logger.debug("Cache expired or missing for category: \(category.rawValue)")
            return nil
        }
        
        return messageCache[category]
    }
    
    private func getRotatedMessage(from messages: [FunnyMessage], for category: FunnyMessage.Category) -> FunnyMessage {
        let currentIndex = currentMessageIndices[category] ?? 0
        let message = messages[currentIndex % messages.count]
        
        // Check if we should rotate to next message
        let timeSinceLastRequest = Date().timeIntervalSince(lastMessageRequestTime)
        if timeSinceLastRequest >= messageRotationInterval {
            let nextIndex = (currentIndex + 1) % messages.count
            currentMessageIndices[category] = nextIndex
            lastMessageRequestTime = Date()
            logger.debug("Rotated to message index \(nextIndex) for category: \(category.rawValue)")
        }
        
        return message
    }
    
    private func refreshMessagesForCategory(_ category: FunnyMessage.Category) async {
        guard !isLoadingMessages else {
            logger.debug("Already loading messages, skipping refresh for: \(category.rawValue)")
            return
        }
        
        isLoadingMessages = true
        logger.info("Refreshing messages for category: \(category.rawValue)")
        
        var newMessages: [FunnyMessage] = []
        
        // Fetch multiple messages to build cache
        for _ in 0..<messageCacheSize {
            do {
                let message = try await apiClient.getFunnyMessage(category: category)
                newMessages.append(message)
                
                // Small delay to get different messages
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
            } catch {
                logger.warning("Failed to fetch message for \(category.rawValue): \(error.localizedDescription)")
                
                // Add fallback message to ensure we have some content
                if newMessages.isEmpty {
                    newMessages.append(createFallbackMessage(for: category))
                }
                break
            }
        }
        
        // Update cache
        if !newMessages.isEmpty {
            messageCache[category] = newMessages
            cacheTimestamps[category] = Date()
            logger.info("Cached \(newMessages.count) messages for category: \(category.rawValue)")
        }
        
        isLoadingMessages = false
    }
    
    private func createFallbackMessage(for category: FunnyMessage.Category) -> FunnyMessage {
        return FunnyMessage(
            message: category.fallbackMessage,
            category: category.rawValue,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
}

// MARK: - Convenience Extensions

extension FunnyMessageService {
    
    /// Get a random message from any category
    func getRandomMessage() async -> FunnyMessage {
        let randomCategory = FunnyMessage.Category.allCases.randomElement() ?? .random
        return await getMessage(for: randomCategory)
    }
    
    /// Get messages for multiple categories concurrently
    func getMessages(for categories: [FunnyMessage.Category]) async -> [FunnyMessage.Category: FunnyMessage] {
        var results: [FunnyMessage.Category: FunnyMessage] = [:]
        
        await withTaskGroup(of: (FunnyMessage.Category, FunnyMessage).self) { group in
            for category in categories {
                group.addTask { [weak self] in
                    guard let self = self else {
                        return (category, FunnyMessage(message: "Loading...", category: category.rawValue, timestamp: ""))
                    }
                    let message = await self.getMessage(for: category)
                    return (category, message)
                }
            }
            
            for await (category, message) in group {
                results[category] = message
            }
        }
        
        return results
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension FunnyMessageService {
    
    /// Debug method to log current cache state
    func debugPrintCacheState() {
        logger.debug("=== Funny Message Cache State ===")
        for category in FunnyMessage.Category.allCases {
            let count = messageCache[category]?.count ?? 0
            let timestamp = cacheTimestamps[category]?.formatted() ?? "Never"
            let currentIndex = currentMessageIndices[category] ?? 0
            logger.debug("\(category.rawValue): \(count) messages, last updated: \(timestamp), current index: \(currentIndex)")
        }
        logger.debug("=== End Cache State ===")
    }
    
    /// Debug method to force refresh a category
    func debugRefreshCategory(_ category: FunnyMessage.Category) async {
        logger.debug("Debug: Force refreshing category: \(category.rawValue)")
        await refreshMessagesForCategory(category)
    }
}
#endif