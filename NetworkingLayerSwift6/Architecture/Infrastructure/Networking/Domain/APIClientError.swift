//
//  APIClientError.swift
//
//  Created by Egzon Pllana.
//

import Foundation

/// An enumeration representing errors that can occur during API client operations.
///
/// This enum encapsulates various errors that may arise when performing network requests, handling responses, or decoding data. Each case provides information about the nature of the error.
///
/// - `invalidURL`: The URL is invalid or cannot be constructed.
/// - `invalidResponse(_ data: Data)`: The response is invalid, and the associated data provides additional context.
/// - `requestFailed(_ error: any Error)`: The request failed due to an underlying error, which is provided.
/// - `decodingFailed(_ error: any Error)`: Decoding the response data failed, with the associated error providing details.
/// - `notExpectedHttpResponseCode(code: Int)`: The HTTP response code was not as expected, with the actual code provided.
/// - `urlRequestIsEmpty`: The URLRequest could not be created.
/// - `statusCode(Int)`: The status code from the server response is provided.
/// - `networkError(any Error)`: A network error occurred, with the underlying error provided.
enum APIClientError: Error {
    case invalidURL
    case invalidResponse(_ data: Data)
    case requestFailed(_ error: any Error)
    case decodingFailed(_ error: any Error)
    case notExpectedHttpResponseCode(code: Int)
    case urlRequestIsEmpty
    case statusCode(Int)
    case networkError(any Error)
}
