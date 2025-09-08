//
//  DeepLinkManager.swift
//  GoPlaces
//
//  Created by Assistant on 08.09.2025.
//

import Foundation
import Combine

final class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    @Published var pendingRoute: Route? = nil
    
    private init() {}
    
    enum Route: Equatable {
        case collections
        case plan
        case myTrips
    }
    
    func handleIncomingURL(_ url: URL) {
        guard url.scheme?.lowercased() == "goplaces" else { return }
        let host = (url.host ?? "").lowercased()
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        let candidate = host.isEmpty ? path : host
        
        switch candidate {
        case "collections":
            pendingRoute = .collections
        case "plan":
            pendingRoute = .plan
        case "mytrips", "trips":
            pendingRoute = .myTrips
        default:
            // Default to collections if unknown
            pendingRoute = .collections
        }
    }
}


