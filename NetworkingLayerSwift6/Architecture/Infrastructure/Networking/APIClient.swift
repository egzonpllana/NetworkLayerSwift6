import Foundation
import Alamofire

final class APIClient: APIClientProtocol {

    // MARK: - Properties -
    private let session: URLSession
    private let interceptors: [any NetworkInterceptor]

    // MARK: - Initialization -
    init(
        session: URLSession = .shared,
        interceptors: [any NetworkInterceptor] = []
    ) {
        self.session = session
        // Note:
        // Using interceptors only for example purposes.
        self.interceptors = interceptors + Interceptors.example
    }

    // MARK: - Methods -
    func request<T: Decodable & Sendable>(
        _ endpoint: any APIEndpointProtocol,
        decoder: JSONDecoder
    ) async throws -> T {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.invalidURL
        }

        let data = try await performRequest(request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIClientError.decodingFailed(error)
        }
    }

    func requestVoid(
        _ endpoint: any APIEndpointProtocol
    ) async throws {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.invalidURL
        }

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

        let request = AF.request(urlRequest)

        do {
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

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIClientError.decodingFailed(error)
            }
        } catch {
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
        var mutableRequest = request

        // Apply request interceptors
        for interceptor in interceptors {
            mutableRequest = interceptor.intercept(request: mutableRequest)
        }

        let session: URLSession
        if let progressDelegate {
            session = URLSession(configuration: .default, delegate: progressDelegate, delegateQueue: nil)
        } else {
            session = self.session
        }

        do {
            let (data, response) = try await session.data(for: mutableRequest)

            // Apply response interceptors
            var modifiedData = data
            var modifiedResponse = response
            for interceptor in interceptors {
                let result = interceptor.intercept(response: modifiedResponse, data: modifiedData)
                modifiedResponse = result.0 ?? modifiedResponse
                modifiedData = result.1 ?? modifiedData
            }

            guard let httpResponse = modifiedResponse as? HTTPURLResponse else {
                throw APIClientError.invalidResponse(modifiedData)
            }

            log("Received HTTP response: \(httpResponse)")
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIClientError.statusCode(httpResponse.statusCode)
            }

            return modifiedData
        } catch {
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
