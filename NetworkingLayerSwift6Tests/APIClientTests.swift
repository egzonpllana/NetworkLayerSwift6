//
//  APIClientTests.swift
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

private struct MockAPIClient: APIClientProtocol {

    var mockedData: Data?
    var mockedError: Error?

    var shouldSimulateRequestError: Bool = false
    func request<T: Codable & Sendable>(
        _ endpoint: any APIEndpointProtocol,
        decoder: JSONDecoder
    ) async throws -> T {
        if shouldSimulateRequestError {
            throw URLError(.badServerResponse)
        }
        
        if let error = mockedError {
            throw error
        }
        guard let data = mockedData else {
            throw NSError(domain: "MockErrorDomain", code: 0, userInfo: nil)
        }
        return try decoder.decode(T.self, from: data)
    }
    
    func requestVoid(
        _ endpoint: any APIEndpointProtocol
    ) async throws {
        if shouldSimulateRequestError {
            throw URLError(.badServerResponse)
        }
        
        if let error = mockedError {
            throw error
        }
    }
    
    func requestWithAlamofire<T>(
        _ endpoint: any APIEndpointProtocol,
        decoder: JSONDecoder
    ) async throws -> T where T : Decodable, T : Sendable {
        if shouldSimulateRequestError {
            throw URLError(.badServerResponse)
        }
        
        if let error = mockedError {
            throw error
        }
        guard let data = mockedData else {
            throw NSError(domain: "MockErrorDomain", code: 0, userInfo: nil)
        }
        return try decoder.decode(T.self, from: data)
    }
    
    @discardableResult
    func requestWithProgress(
        _ endpoint: any APIEndpointProtocol,
        progressDelegate: (any UploadProgressDelegateProtocol)?
    ) async throws -> Data? {
        if shouldSimulateRequestError {
            throw URLError(.badServerResponse)
        }

        if let error = mockedError {
            throw error
        }
        return mockedData
    }
}

// Given
private struct User: Codable, Sendable {
    let id: Int
    let name: String
}

final class APIClientTests: XCTestCase {
    
    private var apiClient: MockAPIClient!
    
    override func setUp() {
        super.setUp()
        apiClient = MockAPIClient()
    }
    
    func testRequest_success() async throws {
        
        let jsonData = "{\"id\":1,\"name\":\"John\"}".data(using: .utf8)
        apiClient.mockedData = jsonData
        
        // When
        let user: User = try await apiClient.request(MockAPIEndpoint(
            method: .get,
            path: "/users/1",
            baseURL: "https://api.example.com",
            headers: [:],
            urlParams: [:],
            body: nil,
            apiVersion: .v1
        ), decoder: JSONDecoder())
        
        // Then
        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.name, "John")
    }
    
    func testRequest_failure() async {
        // Given
        let expectedError = NSError(domain: "MockErrorDomain", code: 1, userInfo: nil)
        apiClient.mockedError = expectedError
        
        // When
        do {
            let _: User = try await apiClient.request(MockAPIEndpoint(
                method: .get,
                path: "/users/1",
                baseURL: "https://api.example.com",
                headers: [:],
                urlParams: [:],
                body: nil,
                apiVersion: .v1
            ), decoder: JSONDecoder())
            XCTFail("Expected error to be thrown")
        } catch let error as NSError {
            // Then
            XCTAssertEqual(error.domain, expectedError.domain)
            XCTAssertEqual(error.code, expectedError.code)
        }
    }
    
    func testRequestData_success() async throws {
        // Given
        let responseData = "some data".data(using: .utf8)
        apiClient.mockedData = responseData
        
        // When
        let data = try await apiClient.requestData(MockAPIEndpoint(
            method: .get,
            path: "/files",
            baseURL: "https://api.example.com",
            headers: [:],
            urlParams: [:],
            body: nil,
            apiVersion: .v1
        ))
        
        // Then
        XCTAssertEqual(data, responseData)
    }
    
    func testRequestData_failure() async {
        // Given
        let expectedError = NSError(domain: "MockErrorDomain", code: 1, userInfo: nil)
        apiClient.mockedError = expectedError
        
        // When
        do {
            _ = try await apiClient.requestData(MockAPIEndpoint(
                method: .get,
                path: "/files",
                baseURL: "https://api.example.com",
                headers: [:],
                urlParams: [:],
                body: nil,
                apiVersion: .v1
            ))
            XCTFail("Expected error to be thrown")
        } catch let error as NSError {
            // Then
            XCTAssertEqual(error.domain, expectedError.domain)
            XCTAssertEqual(error.code, expectedError.code)
        }
    }
    
    func testRequest_defaultDecoder() async throws {
        // Given
        struct User: Codable, Sendable {
            let id: Int
            let name: String
        }
        
        let jsonData = "{\"id\":1,\"name\":\"John\"}".data(using: .utf8)
        apiClient.mockedData = jsonData
        
        // When
        let user: User = try await apiClient.request(MockAPIEndpoint(
            method: .get,
            path: "/users/1",
            baseURL: "https://api.example.com",
            headers: [:],
            urlParams: [:],
            body: nil,
            apiVersion: .v1
        ))
        
        // Then
        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.name, "John")
    }
    
    func testRequestData_validRequest() async throws {
        // Given
        let expectedData = "some data".data(using: .utf8)
        apiClient.mockedData = expectedData
        
        let endpoint = MockAPIEndpoint(
            method: .get,
            path: "/users",
            baseURL: "https://api.example.com",
            headers: [:],
            urlParams: [:],
            body: nil,
            apiVersion: .v1
        )
        
        // When
        let data = try await apiClient.requestWithProgress(endpoint, progressDelegate: nil)
        
        // Then
        XCTAssertNotNil(data, "Expected data to be not nil")
        XCTAssertEqual(data, expectedData, "Expected data to match the mocked data")
    }
    
    func testRequestData_performRequestError() async {
        // Given
        let endpoint = MockAPIEndpoint(
            method: .get,
            path: "/users",
            baseURL: "https://api.example.com",
            headers: [:],
            urlParams: [:],
            body: nil,
            apiVersion: .v1
        )
        
        // Set up MockAPIClient to simulate an error
        apiClient = MockAPIClient(shouldSimulateRequestError: true)
        
        // When/Then
        do {
            _ = try await apiClient.requestWithProgress(endpoint, progressDelegate: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
        }
    }
}
