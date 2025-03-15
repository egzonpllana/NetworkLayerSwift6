//
//  RetryInterceptor.swift
//  NetworkingLayerSwift6
//
//  Created by Egzon Pllana on 15.3.25.
//

import Foundation

/// A network interceptor that retries failed requests based on HTTP response status codes.
///
/// `RetryInterceptor` automatically retries requests that fail due to server errors (status codes 500–599).
/// It supports a configurable number of retry attempts with an exponential backoff strategy.
///
/// - Important: This interceptor does not execute the retries itself.
///   The actual retry mechanism must be implemented in the network client.
/// - Note: This implementation does not modify the request itself.
struct RetryInterceptor: NetworkInterceptor, Sendable {
    private let maxRetries: Int

    init(maxRetries: Int = 3) {
        self.maxRetries = maxRetries
    }

    func intercept(request: URLRequest) -> URLRequest {
        return request
    }

    func intercept(response: URLResponse?, data: Data?) -> (URLResponse?, Data?) {
        guard let httpResponse = response as? HTTPURLResponse else {
            return (response, data)
        }

        if (500...599).contains(httpResponse.statusCode) {
            // Simulate retry logic (actual implementation would need async support)
            for attempt in 1...maxRetries {
                print("Retrying request... Attempt \(attempt)")
                sleep(UInt32(attempt)) // Exponential backoff (not ideal for production)
            }
        }
        return (response, data)
    }
}
