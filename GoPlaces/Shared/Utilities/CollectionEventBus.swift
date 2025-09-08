//
//  CollectionEventBus.swift
//  GoPlaces
//
//  Central event bus to propagate collection updates/deletes across screens.
//

import Foundation
import Combine

enum CollectionEvent {
    case updated(PlaceCollection)
    case deleted(String) // collectionId
    case coverUpdated(collectionId: String, coverURL: String)
}

final class CollectionEventBus: ObservableObject {
    static let shared = CollectionEventBus()
    let events = PassthroughSubject<CollectionEvent, Never>()
    private init() {}
}


