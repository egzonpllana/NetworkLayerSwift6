//
//  APIEndpointTests.swift
//
//  Created by Egzon Pllana.
//

import XCTest
@testable import NetworkingLayerSwift6

// Define a mock endpoint to test
private struct MockAPIEndpoint: APIEndpointProtocol {
    var method: HTTPMethod
    var path: String
    var baseURL: String
    var headers: [String: String]
    var urlParams: [String: any CustomStringConvertible]
    var body: Data?
    var apiVersion: APIVersion
}

// Mock MultipartFormData for testing
struct MockMultipartFormData {
    let boundary: String
    let fileData: Data
    let fileName: String
    let mimeType: String
    let parameters: [String: String]
    
    var asHttpBodyData: Data? {
        // Mock implementation for testing purposes
        return fileData // Simplified for example
    }
}


private func isValidURL(_ url: URL) -> Bool {
    // Perform basic validation or use URL validator
    // For example, check if URL is reachable
    return UIApplication.shared.canOpenURL(url)
}

final class APIEndpointTests: XCTestCase {
    
    func testURLRequestConstruction_success() {
        // Given
        let endpoint = MockAPIEndpoint(
            method: .get,
            path: "users",
            baseURL: "https://api.example.com",
            headers: ["Authorization": "Bearer token"],
            urlParams: ["include": "details"],
            body: nil,
            apiVersion: .v1
        )
        
        // When
        let request = endpoint.urlRequest
        
        // Then
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.url?.absoluteString, "https://api.example.com/api/v1/users?include=details")
        XCTAssertEqual(request?.allHTTPHeaderFields?["Authorization"], "Bearer token")
        XCTAssertNil(request?.httpBody)
    }
    
    func testURLRequestConstruction_withBody() {
        // Given
        let requestBody = "{\"name\":\"John\"}".data(using: .utf8)
        let endpoint = MockAPIEndpoint(
            method: .post,
            path: "users",
            baseURL: "https://api.example.com",
            headers: ["Authorization": "Bearer token", "Content-Type": "application/json"],
            urlParams: [:],
            body: requestBody,
            apiVersion: .v1
        )
        
        // When
        let request = endpoint.urlRequest
        
        // Then
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request!.url!.absoluteString, "https://api.example.com/api/v1/users?")
        XCTAssertEqual(request?.allHTTPHeaderFields?["Authorization"], "Bearer token")
        XCTAssertEqual(request?.allHTTPHeaderFields?["Content-Type"], "application/json")
        XCTAssertEqual(request?.httpBody, requestBody)
    }
    
    func testURLRequestConstruction_noURLParams() {
        // Given
        let endpoint = MockAPIEndpoint(
            method: .delete,
            path: "users/1",
            baseURL: "https://api.example.com",
            headers: [:],
            urlParams: [:],
            body: nil,
            apiVersion: .v1
        )
        
        // When
        let request = endpoint.urlRequest
        
        // Then
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.httpMethod, "DELETE")
        XCTAssertEqual(request?.url?.absoluteString, "https://api.example.com/api/v1/users/1?")
        XCTAssertNil(request?.httpBody)
    }
    
    func testURLRequestConstruction_invalidURL() {
        // Given
        let endpoint = MockAPIEndpoint(
            method: .get,
            path: "/users",
            baseURL: "invalid-url", // Invalid URL
            headers: [:],
            urlParams: [:],
            body: nil,
            apiVersion: .v1
        )
        
        // When
        let request = endpoint.urlRequest
        
        // Then
        XCTAssertNotNil(request, "Expected URLRequest to be non-nil")
        
        // Additional validation
        // Ensure that the URL is invalid
        if let url = request?.url {
            XCTAssertFalse(isValidURL(url), "Expected URL to be invalid but got a valid URL")
        } else {
            XCTFail("URLRequest URL should not be nil")
        }
    }
    
    func testURLRequestConstruction_withEmptyPath() {
        // Given
        let endpoint = MockAPIEndpoint(
            method: .get,
            path: "",
            baseURL: "https://api.example.com",
            headers: [:],
            urlParams: [:],
            body: nil,
            apiVersion: .v1
        )
        
        // When
        let request = endpoint.urlRequest
        
        // Then
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.url?.absoluteString, "https://api.example.com/api/v1/?")
    }
    
    func testBody_createPost() {
        // Given
        let postDTO: PostDTO = .init(userId: 1, title: "Title", body: "Body")
        let endpoint = APIEndpoint.createPost(postDTO)
        
        // When
        let bodyData = endpoint.body
        
        // Then
        let expectedData = postDTO.toJSONData()
        XCTAssertEqual(bodyData, expectedData)
    }
    
    func testBody_uploadImage() {
        // Given
        let imageData = Data(repeating: 0, count: 10) // Mock image data
        let fileName = "test.jpg"
        let mimeType = "image/jpeg"
        let endpoint = APIEndpoint.uploadImage(data: imageData, fileName: fileName, mimeType: ImageMimeType(rawValue: mimeType) ?? .jpeg)
        
        // When
        let bodyData = endpoint.body
        
        // Then
        // Here, you would typically verify the boundary and the multipart form data structure.
        // For simplicity, checking if `bodyData` is not nil is a basic test.
        XCTAssertNotNil(bodyData)
    }
    
    func testBody_getPosts() {
        // Given
        let endpoint = APIEndpoint.getPosts
        
        // When
        let bodyData = endpoint.body
        
        // Then
        XCTAssertNil(bodyData)
    }
}
