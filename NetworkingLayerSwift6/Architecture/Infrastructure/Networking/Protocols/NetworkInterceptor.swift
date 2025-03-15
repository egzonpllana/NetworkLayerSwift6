//
//  NetworkInterceptor.swift
//
//  Created by Egzon Pllana on 14.3.25.
//

import Foundation

/// A protocol that defines a network interceptor, allowing modifications to network requests and responses.
///
/// Conforming types can implement request and response interception logic, such as adding authentication headers,
/// logging network traffic, retrying failed requests, or modifying responses before they reach the caller.
///
/// ## Usage
/// Implement this protocol to customize network behavior. For example:
///
/// ```swift
/// struct AuthInterceptor: NetworkInterceptor {
///     private let tokenProvider: () -> String?
///
///     init(tokenProvider: @escaping () -> String?) {
///         self.tokenProvider = tokenProvider
///     }
///
///     func intercept(request: URLRequest) -> URLRequest {
///         var modifiedRequest = request
///         if let token = tokenProvider() {
///             modifiedRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
///         }
///         return modifiedRequest
///     }
///
///     func intercept(response: URLResponse?, data: Data?) -> (URLResponse?, Data?) {
///         return (response, data)
///     }
/// }
/// ```
///
/// ## Concurrency
/// - This protocol conforms to `Sendable`, meaning all conforming types must be safe to use across concurrent executions.
///
/// ## Example Use Cases
/// - **Authentication:** Add an authorization token to every request.
/// - **Logging:** Log outgoing requests and incoming responses.
/// - **Retries:** Retry failed requests under certain conditions.
/// - **Custom Headers:** Inject common headers like `User-Agent` or `Accept-Language`.
///
protocol NetworkInterceptor: Sendable {
    /// Intercepts and potentially modifies an outgoing network request before it is sent.
    ///
    /// - Parameter request: The original `URLRequest` to be sent.
    /// - Returns: A modified `URLRequest` that will be executed.
    func intercept(request: URLRequest) -> URLRequest

    /// Intercepts and potentially modifies the response received from the network.
    ///
    /// - Parameters:
    ///   - response: The original `URLResponse` received from the server.
    ///   - data: The raw `Data` returned from the request.
    /// - Returns: A tuple containing the modified response and data.
    func intercept(
        response: URLResponse?,
        data: Data?
    ) -> (URLResponse?, Data?)
}
