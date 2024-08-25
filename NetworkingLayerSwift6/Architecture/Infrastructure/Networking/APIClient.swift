import Foundation
import Alamofire

private extension String {
    static let tokenWithSpace = "Token "
    static let authorization = "Authorization"
}

final class APIClient: APIClientProtocol {
    // MARK: - Properties -
    private let token: String?
    private let session: URLSession
    
    // MARK: - Initialization -
    init(token: String? = nil, session: URLSession = .shared) {
        self.token = token
        self.session = session
    }
    
    // MARK: - Methods -
    func request<T: Decodable & Sendable>(
        _ endpoint: any APIEndpointProtocol,
        decoder: JSONDecoder
    ) async throws -> T {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.invalidURL
        }
        
        // Perform the network request and decode the data
        let data = try await performRequest(request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            // Handle decoding errors
            throw APIClientError.decodingFailed(error)
        }
    }
    
    func requestVoid(
        _ endpoint: any APIEndpointProtocol
    ) async throws {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.invalidURL
        }
        
        // Perform the network request
       try await performRequest(request)
    }
    
    @discardableResult
    func requestWithProgress(
        _ endpoint: any APIEndpointProtocol,
        progressDelegate: (
            any UploadProgressDelegateProtocol
        )?
    ) async throws -> Data? {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.urlRequestIsEmpty
        }
        
        do {
            let data = try await performRequest(request, progressDelegate: progressDelegate)
            return data
        } catch {
            throw error
        }
    }
}

// Additional method just in case you want to work with Alamofire framework.
extension APIClient {
    
    func requestWithAlamofire<T: Decodable & Sendable>(
        _ endpoint: any APIEndpointProtocol,
        decoder: JSONDecoder
    ) async throws -> T {
        guard let urlRequest = endpoint.urlRequest else {
            throw APIClientError.invalidURL
        }

        // Create a request using Alamofire
        let request = AF.request(urlRequest)

        do {
            // Await the Alamofire request
            let data = try await withCheckedThrowingContinuation { continuation in
                request.responseData { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // Decode the response data
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIClientError.decodingFailed(error)
            }
        } catch {
            // Handle Alamofire errors
            if let urlError = error as? URLError {
                throw APIClientError.networkError(urlError)
            } else {
                throw APIClientError.requestFailed(error)
            }
        }
    }
}

// MARK: - Private extensions -
private extension APIClient {
    
    @discardableResult
    private func performRequest(
        _ request: URLRequest,
        progressDelegate: (any UploadProgressDelegateProtocol)? = nil
    ) async throws -> Data {
        // Inject token if available
        if let token = token {
            var mutableRequest = request
            mutableRequest.addValue(.tokenWithSpace + String(token), forHTTPHeaderField: .authorization)
        }
        
        // Configure session
        let session: URLSession
        if let progressDelegate {
            session = URLSession(configuration: .default, delegate: progressDelegate, delegateQueue: nil)
        } else {
            session = self.session
        }
        
        do {
            // Perform the network request
            let (data, response) = try await session.data(for: request)
            
            // Ensure the response is an HTTP URL response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIClientError.invalidResponse(data)
            }
            
            // Log the HTTP response
            log("Received HTTP response: \(httpResponse)")
            
            // Validate HTTP status code
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIClientError.statusCode(httpResponse.statusCode)
            }
            
            return data
        } catch {
            // Handle specific errors
            if let urlError = error as? URLError {
                throw APIClientError.networkError(urlError)
            } else {
                throw APIClientError.requestFailed(error)
            }
        }
    }
}

// MARK: - Log extension -
private extension APIClient {
    
    private func log(_ string: String) {
        #if DEBUG
        print(string)
        #endif
    }
}
