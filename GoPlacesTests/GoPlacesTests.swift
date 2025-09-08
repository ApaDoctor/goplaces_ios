//
//  GoPlacesTests.swift
//  GoPlacesTests
//
//  Updated for SwiftData and API Client integration
//  Created by Volodymyr Piskun on 04.09.2025.
//

import XCTest
import SwiftData
@testable import GoPlaces

@MainActor
final class GoPlacesTests: XCTestCase {
    
    var testModelContainer: ModelContainer!
    var testModelContext: ModelContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([Place.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        testModelContainer = try ModelContainer(for: schema, configurations: [configuration])
        testModelContext = testModelContainer.mainContext
    }
    
    override func tearDownWithError() throws {
        testModelContext = nil
        testModelContainer = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Place Model Tests
    
    func testPlaceCreation() throws {
        let place = Place(
            name: "Test Place",
            address: "123 Test Street, Test City, TC 12345",
            instagramURL: "https://instagram.com/p/test123/",
            rating: 4.5,
            photoURL: "https://example.com/photo.jpg",
            phoneNumber: "+1-555-123-4567",
            website: "https://testplace.com"
        )
        
        XCTAssertNotNil(place.id)
        XCTAssertEqual(place.name, "Test Place")
        XCTAssertEqual(place.address, "123 Test Street, Test City, TC 12345")
        XCTAssertEqual(place.instagramURL, "https://instagram.com/p/test123/")
        XCTAssertEqual(place.rating, 4.5)
        XCTAssertEqual(place.photoURL, "https://example.com/photo.jpg")
        XCTAssertEqual(place.phoneNumber, "+1-555-123-4567")
        XCTAssertEqual(place.website, "https://testplace.com")
        XCTAssertNotNil(place.addedDate)
    }
    
    func testPlaceValidation() throws {
        let validPlace = Place(
            name: "Valid Place",
            address: "123 Test Street",
            instagramURL: "https://instagram.com/p/valid/"
        )
        
        // Should not throw
        try validPlace.validate()
        
        // Test invalid name (empty)
        let invalidPlace1 = Place(
            name: "",
            address: "123 Test Street", 
            instagramURL: "https://instagram.com/p/test/"
        )
        
        XCTAssertThrowsError(try invalidPlace1.validate()) { error in
            XCTAssertTrue(error is PlaceValidationError)
            XCTAssertEqual(error as? PlaceValidationError, .nameRequired)
        }
        
        // Test invalid URL
        let invalidPlace2 = Place(
            name: "Test Place",
            address: "123 Test Street",
            instagramURL: "not-a-valid-url"
        )
        
        XCTAssertThrowsError(try invalidPlace2.validate()) { error in
            XCTAssertTrue(error is PlaceValidationError)
            XCTAssertEqual(error as? PlaceValidationError, .invalidInstagramURL)
        }
        
        // Test invalid rating
        let invalidPlace3 = Place(
            name: "Test Place",
            address: "123 Test Street",
            instagramURL: "https://instagram.com/p/test/",
            rating: 6.0 // Invalid rating > 5.0
        )
        
        XCTAssertThrowsError(try invalidPlace3.validate()) { error in
            XCTAssertTrue(error is PlaceValidationError)
            XCTAssertEqual(error as? PlaceValidationError, .ratingOutOfRange)
        }
    }
    
    func testPlaceComputedProperties() throws {
        let place = Place(
            name: "Test Place",
            address: "123 Test Street",
            instagramURL: "https://instagram.com/p/test/",
            rating: 4.2
        )
        
        XCTAssertEqual(place.displayName, "Test Place")
        XCTAssertEqual(place.displayAddress, "123 Test Street")
        XCTAssertEqual(place.formattedRating, "4.2")
        XCTAssertTrue(place.hasValidInstagramURL)
        XCTAssertNotNil(place.instagramURLObject)
        XCTAssertEqual(place.instagramURLObject?.absoluteString, "https://instagram.com/p/test/")
    }
    
    func testPlaceWithEmptyFields() throws {
        let place = Place(
            name: "",
            address: "",
            instagramURL: "https://instagram.com/p/test/",
            rating: 0.0
        )
        
        XCTAssertEqual(place.displayName, AppConstants.Place.Defaults.placeholderName)
        XCTAssertEqual(place.displayAddress, AppConstants.Place.Defaults.unknownAddress)
        XCTAssertNil(place.formattedRating)
        XCTAssertFalse(place.hasValidCoordinates) // Not implemented yet
    }
    
    // MARK: - SwiftData Integration Tests
    
    func testPlaceSwiftDataIntegration() throws {
        let place = Place(
            name: "SwiftData Test Place",
            address: "456 SwiftData Street",
            instagramURL: "https://instagram.com/p/swiftdata/"
        )
        
        // Insert into context
        testModelContext.insert(place)
        
        // Save context
        try testModelContext.save()
        
        // Fetch from context
        let fetchDescriptor = FetchDescriptor<Place>()
        let fetchedPlaces = try testModelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(fetchedPlaces.count, 1)
        let fetchedPlace = fetchedPlaces[0]
        XCTAssertEqual(fetchedPlace.name, "SwiftData Test Place")
        XCTAssertEqual(fetchedPlace.address, "456 SwiftData Street")
        XCTAssertEqual(fetchedPlace.instagramURL, "https://instagram.com/p/swiftdata/")
    }
    
    func testMultiplePlacesStorage() throws {
        let places = [
            Place(name: "Place 1", address: "Address 1", instagramURL: "https://instagram.com/p/1/"),
            Place(name: "Place 2", address: "Address 2", instagramURL: "https://instagram.com/p/2/"),
            Place(name: "Place 3", address: "Address 3", instagramURL: "https://instagram.com/p/3/")
        ]
        
        // Insert all places
        for place in places {
            testModelContext.insert(place)
        }
        
        try testModelContext.save()
        
        // Fetch all places
        let fetchDescriptor = FetchDescriptor<Place>()
        let fetchedPlaces = try testModelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(fetchedPlaces.count, 3)
        
        let names = Set(fetchedPlaces.map { $0.name })
        XCTAssertTrue(names.contains("Place 1"))
        XCTAssertTrue(names.contains("Place 2"))
        XCTAssertTrue(names.contains("Place 3"))
    }
    
    // MARK: - Performance Tests
    
    func testPlaceCreationPerformance() throws {
        measure {
            let place = Place(
                name: "Performance Test Place",
                address: "123 Performance Street",
                instagramURL: "https://instagram.com/p/performance/"
            )
            XCTAssertNotNil(place)
        }
    }
    
    func testPlaceValidationPerformance() throws {
        let place = Place(
            name: "Performance Test Place",
            address: "123 Performance Street",
            instagramURL: "https://instagram.com/p/performance/"
        )
        
        measure {
            do {
                try place.validate()
            } catch {
                XCTFail("Validation should succeed")
            }
        }
    }
    
    func testSwiftDataFetchPerformance() throws {
        // Insert test data
        for i in 1...100 {
            let place = Place(
                name: "Place \(i)",
                address: "Address \(i)",
                instagramURL: "https://instagram.com/p/\(i)/"
            )
            testModelContext.insert(place)
        }
        try testModelContext.save()
        
        // Measure fetch performance
        measure {
            do {
                let fetchDescriptor = FetchDescriptor<Place>()
                let places = try testModelContext.fetch(fetchDescriptor)
                XCTAssertEqual(places.count, 100)
            } catch {
                XCTFail("Fetch should succeed")
            }
        }
    }
}