//
//  APIEndpointProtocol.swift
//
//  Created by Egzon Pllana.
//

import Foundation

/// A protocol defining the requirements for an API endpoint.
///
/// This protocol specifies the necessary components to construct a URL request for an API endpoint. It includes details such as the HTTP method, path, base URL, headers, URL parameters, body, and API version. Conforming types must provide these components to enable API requests.
///
/// - `method`: The HTTP method to be used for the request (e.g., GET, POST).
/// - `path`: The specific path for the endpoint relative to the base URL.
/// - `baseURL`: The base URL for the API.
/// - `headers`: A dictionary of HTTP headers to include in the request.
/// - `urlParams`: A dictionary of query parameters to include in the URL. The values must conform to `CustomStringConvertible`.
/// - `body`: The body of the request, if any, as `Data`.
/// - `urlRequest`: A computed `URLRequest` based on the provided components. Returns `nil` if the URL cannot be constructed.
/// - `apiVersion`: The version of the API being used.
///
protocol APIEndpointProtocol {
    /// HTTP method used by the endpoint.
    var method: HTTPMethod { get }
    
    /// Path for the endpoint.
    var path: String { get }
    
    /// Base URL for the API.
    var baseURL: String { get }
    
    /// Headers for the request.
    var headers: [String: String] { get }
    
    /// URL parameters for the request.
    var urlParams: [String: any CustomStringConvertible] { get }
    
    /// Body data for the request.
    var body: Data? { get }
    
    /// URLRequest representation of the endpoint.
    var urlRequest: URLRequest? { get }
    
    /// API version used by the endpoint.
    var apiVersion: APIVersion { get }
}

extension APIEndpointProtocol {
    
    /// A computed property that constructs and returns a `URLRequest` for the endpoint.
    ///
    /// This property assembles a `URLRequest` by combining the base URL, API version, and path. It adds any query parameters and sets the HTTP method, headers, and body as specified by the endpoint.
    ///
    /// - Returns: A `URLRequest` if the URL components can be successfully created, otherwise `nil`.
    ///
    /// ### Example
    /// ```swift
    /// let request = endpoint.urlRequest
    /// // Use the request with URLSession or any networking library.
    /// ```
    var urlRequest: URLRequest? {
        var components = URLComponents(string: baseURL + apiVersion.rawValue + path)
        components?.queryItems = urlParams.map { key, value in
            URLQueryItem(name: key, value: String(describing: value))
        }
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        return request
    }
}
