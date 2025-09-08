//
//  APIClientTests.swift
//  GoPlacesTests
//
//  Unit tests for API client functionality
//  Created by Volodymyr Piskun on 04.09.2025.
//

import XCTest
import SwiftData
@testable import GoPlaces

@MainActor
final class APIClientTests: XCTestCase {
    
    var apiClient: APIClient!
    var mockModelContainer: ModelContainer!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create API client
        apiClient = APIClient()
        
        // Create in-memory model container for testing
        let schema = Schema([Place.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        mockModelContainer = try ModelContainer(for: schema, configurations: [configuration])
    }
    
    override func tearDownWithError() throws {
        apiClient = nil
        mockModelContainer = nil
        try super.tearDownWithError()
    }
    
    // MARK: - API Client Tests
    
    func testAPIClientInitialization() throws {
        XCTAssertNotNil(apiClient)
        XCTAssertEqual(apiClient.activeJobsCount, 0)
    }
    
    func testHealthCheckWithNetworkUnavailable() async throws {
        // When network is unavailable, health check should return false
        apiClient.isNetworkAvailable = false
        let isHealthy = try await apiClient.checkHealth()
        XCTAssertFalse(isHealthy)
    }
    
    func testExtractPlacesWithInvalidURL() async throws {
        // Test with empty URL
        do {
            _ = try await apiClient.extractPlaces(from: "")
            XCTFail("Should have thrown an error for empty URL")
        } catch let error as APIError {
            XCTAssertEqual(error.code, "INVALID_URL")
        }
        
        // Test with invalid URL
        do {
            _ = try await apiClient.extractPlaces(from: "not-a-valid-url")
            XCTFail("Should have thrown an error for invalid URL")
        } catch let error as APIError {
            XCTAssertEqual(error.code, "INVALID_URL")
        }
    }
    
    func testExtractPlacesWithNetworkUnavailable() async throws {
        apiClient.isNetworkAvailable = false
        
        do {
            _ = try await apiClient.extractPlaces(from: "https://instagram.com/test")
            XCTFail("Should have thrown network unavailable error")
        } catch let error as APIError {
            XCTAssertEqual(error.code, "NETWORK_UNAVAILABLE")
        }
    }
    
    func testErrorHandling() throws {
        // Test URL error handling
        let urlError = URLError(.notConnectedToInternet)
        let apiError = apiClient.handleNetworkError(urlError)
        XCTAssertEqual(apiError.code, "NETWORK_UNAVAILABLE")
        
        // Test timeout error
        let timeoutError = URLError(.timedOut)
        let timeoutAPIError = apiClient.handleNetworkError(timeoutError)
        XCTAssertEqual(timeoutAPIError.code, "TIMEOUT")
        
        // Test generic error
        let genericError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let genericAPIError = apiClient.handleNetworkError(genericError)
        XCTAssertEqual(genericAPIError.code, "UNKNOWN_ERROR")
        XCTAssertEqual(genericAPIError.message, "Test error")
    }
    
    func testJobManagement() throws {
        // Initially no active jobs
        XCTAssertEqual(apiClient.activeJobsCount, 0)
        
        // Cancel all jobs (should be safe even when empty)
        apiClient.cancelAllJobs()
        XCTAssertEqual(apiClient.activeJobsCount, 0)
    }
    
    // MARK: - API Models Tests
    
    func testPlaceExtractionRequestEncoding() throws {
        let request = PlaceExtractionRequest(url: "https://instagram.com/test")
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["url"] as? String, "https://instagram.com/test")
    }
    
    func testPlaceExtractionResponseDecoding() throws {
        let jsonString = """
        {
            "job_id": "test-123",
            "status": "processing",
            "estimated_completion": "2025-09-04T20:00:00Z"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let response = try decoder.decode(PlaceExtractionResponse.self, from: data)
        XCTAssertEqual(response.jobId, "test-123")
        XCTAssertEqual(response.status.rawValue, "processing")
        XCTAssertNotNil(response.estimatedCompletion)
    }
    
    func testJobStatusResponseDecoding() throws {
        let jsonString = """
        {
            "job_id": "test-123",
            "status": "completed",
            "result": {
                "url": "https://instagram.com/test",
                "platform": "instagram",
                "extracted_places": [
                    {
                        "id": "place-1",
                        "name": "Test Place",
                        "confidence_score": 0.95,
                        "google_place": {
                            "place_id": "ChIJ123",
                            "name": "Test Place",
                            "formatted_address": "123 Test St, Test City",
                            "rating": 4.5,
                            "place_types": ["restaurant"],
                            "photos": ["https://example.com/photo.jpg"],
                            "website": "https://testplace.com",
                            "phone_number": "+1234567890"
                        }
                    }
                ],
                "processing_metadata": {
                    "processing_time_seconds": 3.0,
                    "api_cost": 0.05
                }
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let response = try decoder.decode(JobStatusResponse.self, from: data)
        XCTAssertEqual(response.jobId, "test-123")
        XCTAssertEqual(response.status, .completed)
        XCTAssertNotNil(response.result)
        
        let result = response.result!
        XCTAssertEqual(result.url, "https://instagram.com/test")
        XCTAssertEqual(result.platform, "instagram")
        XCTAssertEqual(result.extractedPlaces.count, 1)
        
        let place = result.extractedPlaces[0]
        XCTAssertEqual(place.name, "Test Place")
        XCTAssertEqual(place.confidenceScore, 0.95)
        XCTAssertNotNil(place.googlePlace)
        
        let googlePlace = place.googlePlace!
        XCTAssertEqual(googlePlace.name, "Test Place")
        XCTAssertEqual(googlePlace.rating, 4.5)
        XCTAssertEqual(googlePlace.placeTypes, ["restaurant"])
    }
    
    func testAPIErrorDecoding() throws {
        let jsonString = """
        {
            "code": "EXTRACTION_FAILED",
            "message": "Failed to extract places from content",
            "details": {
                "reason": "No places found"
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let error = try decoder.decode(APIError.self, from: data)
        XCTAssertEqual(error.code, "EXTRACTION_FAILED")
        XCTAssertEqual(error.message, "Failed to extract places from content")
        XCTAssertEqual(error.details?["reason"], "No places found")
        XCTAssertEqual(error.localizedDescription, "Failed to extract places from content")
    }
    
    func testExtractionResultToPlaceModelsConversion() throws {
        let extractedPlace = ExtractedPlace(
            id: "test-1",
            name: "Test Place",
            confidenceScore: 0.95,
            googlePlace: GooglePlaceDetails(
                placeId: "ChIJ123",
                name: "Test Restaurant",
                formattedAddress: "123 Test Street, Test City, TC 12345",
                rating: 4.5,
                placeTypes: ["restaurant", "food"],
                photos: ["https://example.com/photo1.jpg", "https://example.com/photo2.jpg"],
                website: "https://testrestaurant.com",
                phoneNumber: "+1-555-123-4567"
            )
        )
        
        let result = ExtractionResult(
            url: "https://instagram.com/p/test123/",
            platform: "instagram",
            extractedPlaces: [extractedPlace],
            processingMetadata: ProcessingMetadata(
                processingTimeSeconds: 2.5,
                apiCost: 0.03
            )
        )
        
        let places = result.toPlaceModels(sourceURL: "https://instagram.com/p/test123/")
        
        XCTAssertEqual(places.count, 1)
        let place = places[0]
        XCTAssertEqual(place.name, "Test Restaurant")
        XCTAssertEqual(place.address, "123 Test Street, Test City, TC 12345")
        XCTAssertEqual(place.instagramURL, "https://instagram.com/p/test123/")
        XCTAssertEqual(place.rating, 4.5)
        XCTAssertEqual(place.photoURL, "https://example.com/photo1.jpg")
        XCTAssertEqual(place.website, "https://testrestaurant.com")
        XCTAssertEqual(place.phoneNumber, "+1-555-123-4567")
    }
    
    func testExtractionResultToPlaceModelsWithoutGooglePlace() throws {
        let extractedPlace = ExtractedPlace(
            id: "test-1",
            name: "Basic Place",
            confidenceScore: 0.7,
            googlePlace: nil
        )
        
        let result = ExtractionResult(
            url: "https://instagram.com/p/test123/",
            platform: "instagram",
            extractedPlaces: [extractedPlace],
            processingMetadata: nil
        )
        
        let places = result.toPlaceModels(sourceURL: "https://instagram.com/p/test123/")
        
        XCTAssertEqual(places.count, 1)
        let place = places[0]
        XCTAssertEqual(place.name, "Basic Place")
        XCTAssertEqual(place.address, "")
        XCTAssertEqual(place.instagramURL, "https://instagram.com/p/test123/")
        XCTAssertEqual(place.rating, 0.0)
        XCTAssertNil(place.photoURL)
        XCTAssertNil(place.website)
        XCTAssertNil(place.phoneNumber)
    }
    
    // MARK: - Performance Tests
    
    func testAPIClientPerformance() throws {
        measure {
            let client = APIClient()
            XCTAssertNotNil(client)
            XCTAssertEqual(client.activeJobsCount, 0)
        }
    }
    
    func testJSONDecodingPerformance() throws {
        let jsonString = """
        {
            "job_id": "test-123",
            "status": "completed",
            "result": {
                "url": "https://instagram.com/test",
                "platform": "instagram",
                "extracted_places": [
                    {
                        "id": "place-1",
                        "name": "Test Place",
                        "confidence_score": 0.95,
                        "google_place": {
                            "place_id": "ChIJ123",
                            "name": "Test Place",
                            "formatted_address": "123 Test St, Test City",
                            "rating": 4.5,
                            "place_types": ["restaurant"],
                            "photos": ["https://example.com/photo.jpg"],
                            "website": "https://testplace.com",
                            "phone_number": "+1234567890"
                        }
                    }
                ]
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        measure {
            _ = try! decoder.decode(JobStatusResponse.self, from: data)
        }
    }
}