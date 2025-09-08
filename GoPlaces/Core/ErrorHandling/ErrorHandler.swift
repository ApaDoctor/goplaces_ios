//
//  ErrorHandler.swift
//  GoPlaces
//
//  Created by Volodymyr Piskun on 03.09.2025.
//

import Foundation
import os.log
import SwiftUI

// MARK: - App Error Types
enum AppError: LocalizedError, Equatable {
    case coreDataNotAvailable
    case coreDataMigrationFailed(Error)
    case networkUnavailable
    case invalidInput(String)
    case permissionDenied(String)
    case serviceUnavailable(String)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .coreDataNotAvailable:
            return "Data storage is not available. Please restart the app."
        case .coreDataMigrationFailed:
            return "Failed to migrate data to new version. Please contact support."
        case .networkUnavailable:
            return "Network connection is not available. Please check your connection."
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .permissionDenied(let permission):
            return "Permission denied: \(permission). Please check app settings."
        case .serviceUnavailable(let service):
            return "\(service) is currently unavailable. Please try again later."
        case .unknownError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .coreDataNotAvailable, .coreDataMigrationFailed:
            return "Try restarting the app. If the problem persists, contact support."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .invalidInput:
            return "Please check your input and try again."
        case .permissionDenied:
            return "Go to Settings > Privacy to grant necessary permissions."
        case .serviceUnavailable:
            return "Please wait a moment and try again."
        case .unknownError:
            return "If this problem persists, please contact support."
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.coreDataNotAvailable, .coreDataNotAvailable),
             (.networkUnavailable, .networkUnavailable):
            return true
        case (.coreDataMigrationFailed, .coreDataMigrationFailed),
             (.invalidInput, .invalidInput),
             (.permissionDenied, .permissionDenied),
             (.serviceUnavailable, .serviceUnavailable),
             (.unknownError, .unknownError):
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Severity
enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var logLevel: OSLogType {
        switch self {
        case .low: return .debug
        case .medium: return .info
        case .high: return .error
        case .critical: return .fault
        }
    }
}

// MARK: - Error Handler
@MainActor
final class ErrorHandler: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ErrorHandler()
    
    // MARK: - Properties
    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    
    private let logger = Logger(subsystem: "com.goplaces.app", category: "ErrorHandler")
    private var errorCount: [String: Int] = [:]
    
    private init() {
        setupNotificationHandlers()
    }
    
    // MARK: - Public Methods
    
    /// Handle an error with automatic severity detection
    func handle(_ error: Error, severity: ErrorSeverity? = nil) {
        let appError = convertToAppError(error)
        let errorSeverity = severity ?? detectSeverity(for: appError)
        
        logError(appError, severity: errorSeverity)
        
        if shouldShowUserAlert(for: appError, severity: errorSeverity) {
            showErrorToUser(appError)
        }
        
        trackErrorOccurrence(appError)
    }
    
    /// Handle an error with custom message
    func handleWithMessage(_ error: Error, message: String, severity: ErrorSeverity = .medium) {
        let customError = AppError.unknownError(error)
        handle(customError, severity: severity)
    }
    
    /// Clear current error
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
    
    /// Get error statistics for debugging
    func getErrorStatistics() -> [String: Int] {
        return errorCount
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationHandlers() {
        NotificationCenter.default.addObserver(
            forName: .coreDataStackFailure,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                if let error = notification.userInfo?["error"] as? Error {
                    self?.handle(AppError.coreDataMigrationFailed(error), severity: .critical)
                } else {
                    self?.handle(AppError.coreDataNotAvailable, severity: .critical)
                }
            }
        }
    }
    
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // SwiftData errors (replacing CoreData error handling)
        if error.localizedDescription.contains("SwiftData") || error.localizedDescription.contains("ModelContainer") {
            return .coreDataNotAvailable // Reusing existing error type for SwiftData issues
        }
        
        // Handle generic validation errors
        if error.localizedDescription.contains("validation") || error.localizedDescription.contains("invalid") {
            return .invalidInput(error.localizedDescription)
        }
        
        // Network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            default:
                return .serviceUnavailable("Network service")
            }
        }
        
        return .unknownError(error)
    }
    
    private func detectSeverity(for error: AppError) -> ErrorSeverity {
        switch error {
        case .coreDataNotAvailable, .coreDataMigrationFailed:
            return .critical
        case .networkUnavailable:
            return .medium
        case .invalidInput:
            return .low
        case .permissionDenied:
            return .medium
        case .serviceUnavailable:
            return .medium
        case .unknownError:
            return .high
        }
    }
    
    private func logError(_ error: AppError, severity: ErrorSeverity) {
        let message = "[\(severity.rawValue.uppercased())] \(error.errorDescription ?? "Unknown error")"
        logger.log(level: severity.logLevel, "\(message)")
        
        // In production, you might want to send this to a crash reporting service
        #if DEBUG
        print("🚨 \(message)")
        if let recovery = error.recoverySuggestion {
            print("💡 Recovery: \(recovery)")
        }
        #endif
    }
    
    private func shouldShowUserAlert(for error: AppError, severity: ErrorSeverity) -> Bool {
        // Don't overwhelm user with too many alerts
        let errorKey = String(describing: error)
        let count = errorCount[errorKey, default: 0]
        
        // Show alert for first occurrence or critical errors
        return count == 0 || severity == .critical
    }
    
    private func showErrorToUser(_ error: AppError) {
        currentError = error
        showErrorAlert = true
    }
    
    private func trackErrorOccurrence(_ error: AppError) {
        let errorKey = String(describing: error)
        errorCount[errorKey, default: 0] += 1
    }
}

// MARK: - SwiftUI Integration
struct ErrorHandlerView<Content: View>: View {
    @StateObject private var errorHandler = ErrorHandler.shared
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .alert("Error", isPresented: $errorHandler.showErrorAlert) {
                Button("OK") {
                    errorHandler.clearError()
                }
                if let error = errorHandler.currentError,
                   let _ = error.recoverySuggestion {
                    Button("Help") {
                        // Could open help/support page
                        errorHandler.clearError()
                    }
                }
            } message: {
                if let error = errorHandler.currentError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.errorDescription ?? "An error occurred")
                        if let recovery = error.recoverySuggestion {
                            Text(recovery)
                                .font(.caption)
                        }
                    }
                }
            }
    }
}

// MARK: - Convenience Extensions
extension View {
    func handleErrors() -> some View {
        ErrorHandlerView {
            self
        }
    }
}