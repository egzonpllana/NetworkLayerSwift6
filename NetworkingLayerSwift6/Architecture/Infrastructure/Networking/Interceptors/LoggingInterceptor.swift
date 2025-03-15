//
//  LoggingInterceptor.swift
//  NetworkingLayerSwift6
//
//  Created by Egzon Pllana on 15.3.25.
//

import Foundation

/// A network interceptor that logs request and response details for debugging purposes.
///
/// The `LoggingInterceptor` helps track outgoing requests and incoming responses,
/// making it easier to debug API calls and inspect request headers, body, and responses.
///
/// - Important: This interceptor should be used only in debug builds to avoid exposing sensitive data in production logs.
struct LoggingInterceptor: NetworkInterceptor, Sendable {

    func intercept(request: URLRequest) -> URLRequest {
        logRequest(request)
        return request
    }

    func intercept(
        response: URLResponse?,
        data: Data?
    ) -> (URLResponse?, Data?) {
        logResponse(response, data: data)
        return (response, data)
    }
}

// MARK: - Private Logging Methods

private extension LoggingInterceptor {
    func logRequest(_ request: URLRequest) {
        #if DEBUG
        print("➡️ [Request] \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")

        if let headers = request.allHTTPHeaderFields {
            print("Headers: \(headers)")
        }

        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        #endif
    }
    func logResponse(_ response: URLResponse?, data: Data?) {
        #if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
            print("⬅️ [Response] \(httpResponse.statusCode) \(httpResponse.url?.absoluteString ?? "")")
        }

        if let data, let responseString = String(data: data, encoding: .utf8) {
            print("Response Body: \(responseString)")
        }
        #endif
    }
}
