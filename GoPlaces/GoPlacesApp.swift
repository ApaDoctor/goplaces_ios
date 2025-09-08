//
//  GoPlacesApp.swift
//  GoPlaces
//
//  Created by Volodymyr Piskun on 03.09.2025.
//

import SwiftUI
import SwiftData
import os.log
import Combine

@main
struct GoPlacesApp: App {
    
    // MARK: - Properties
    @StateObject private var sharedDataManager = SharedDataManager.shared
    @StateObject private var errorHandler = ErrorHandler.shared
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    
    private let logger = Logger(subsystem: "com.goplaces.app", category: "App")
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(sharedDataManager.modelContainer)
                .environmentObject(sharedDataManager)
                .environmentObject(deepLinkManager)
                .handleErrors()
                .onAppear {
                    performAppStartupChecks()
                }
                .onOpenURL { url in
                    Logger(subsystem: "com.goplaces.app", category: "DeepLink").info("Received URL: \(url.absoluteString, privacy: .public)")
                    deepLinkManager.handleIncomingURL(url)
                }
        }
    }
    
    // MARK: - Private Methods
    
    private func performAppStartupChecks() {
        logger.info("App startup initiated with SharedDataManager")
        
        // SwiftData handles migrations automatically via SharedDataManager
        logger.info("SharedDataManager container initialized successfully with App Group: \(AppConstants.AppGroup.identifier)")
        
        logger.info("App startup completed successfully")
    }
}

// MARK: - App Root View
struct AppRootView: View {
    @StateObject private var errorHandler = ErrorHandler.shared
    
    var body: some View {
        Group {
            if errorHandler.currentError?.severity == .critical {
                // Show critical error recovery view
                CriticalErrorView()
            } else {
                MainTabView()
            }
        }
    }
}

// MARK: - Critical Error View
struct CriticalErrorView: View {
    @StateObject private var errorHandler = ErrorHandler.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Critical Error")
                .font(.title)
                .fontWeight(.bold)
            
            if let error = errorHandler.currentError {
                Text(error.errorDescription ?? "An unexpected error occurred")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let recovery = error.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Button("Restart App") {
                // In a real app, you might want to trigger app restart
                errorHandler.clearError()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

// MARK: - Error Severity Extension
private extension AppError {
    var severity: ErrorSeverity {
        switch self {
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
}
