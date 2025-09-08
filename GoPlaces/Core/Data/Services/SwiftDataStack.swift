//
//  SwiftDataStack.swift
//  GoPlaces
//
//  SwiftData container setup for Place model
//  Created by Volodymyr Piskun on 04.09.2025.
//

import SwiftData
import Foundation

/// SwiftData container configuration for GoPlaces app
class SwiftDataStack {
    static let shared = SwiftDataStack()
    
    lazy var container: ModelContainer = {
        let schema = Schema([
            Place.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    private init() {}
    
    /// Create a new model context for operations
    func newContext() -> ModelContext {
        return ModelContext(container)
    }
    
    /// Main context for UI operations
    @MainActor
    var mainContext: ModelContext {
        return container.mainContext
    }
}

// App Group identifier already defined in AppConstants.AppGroup