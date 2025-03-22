//
//  APIEndpoint.swift
//
//  Created by Egzon Pllana.
//

import Foundation
import EventHorizon

private enum Constants {
    static let baseURL = "https://jsonplaceholder.typicode.com"
    static let uploadPath = "upload"
    static let postPath = "posts"
    static let contentTypeHeader = "Content-Type"
}

// Endpoints
enum APIEndpointExample {
    case getPosts
    case createPost(PostDTO)
    case uploadImage(data: Data, fileName: String, mimeType: ImageMimeType)
}

/// Extension to conform to `APIEndpointProtocol`.
extension APIEndpointExample: APIEndpointProtocol {

    var apiVersion: String {
        APIVersion.v1.rawValue
    }

    /// Endpoint base URL.
    var baseURL: String {
        return Constants.baseURL
    }

    /// Endpoint HTTP method.
    var method: HTTPMethod {
        switch self {
            case .getPosts:
                return .get
            case .createPost, .uploadImage:
                return .post
        }
    }

    /// Endpoint path.
    var path: String {
        switch self {
            case .getPosts, .createPost:
                return Constants.postPath
            case .uploadImage:
                return Constants.uploadPath
        }
    }

    /// Request headers.
    var headers: [String: String] {
        guard let body = body else { return [:] }
        return [Constants.contentTypeHeader: body.contentType]
    }

    /// Request URL parameters.
    var urlParams: [String: any CustomStringConvertible] {
        return [:]
    }

    /// Request body data.
    var body: HTTPBody? {
        switch self {
            case .createPost(let postDTO):
                guard let postData = postDTO.toJSONData() else {
                    return nil
                }
                return .data(postData)
            case .uploadImage(let data, let fileName, let mimeType):
                let multipartData = MultipartFormData(
                    boundary: UUID().uuidString,
                    fileData: data,
                    fileName: fileName,
                    mimeType: mimeType.asString,
                    parameters: [:]
                )
                return .multipartFormData(multipartData)
            case .getPosts:
                return nil
        }
    }
}
