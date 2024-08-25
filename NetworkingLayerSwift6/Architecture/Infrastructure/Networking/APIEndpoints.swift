//
//  APIEndpoint.swift
//
//  Created by Egzon Pllana.
//

import Foundation

private enum Constants {
    static let baseURL = "https://jsonplaceholder.typicode.com"
    static let uploadPath = "upload"
    static let postPath = "posts"
    
    static let contentTypeHeader = "Content-Type"
    static let multipartFormDataContentType = "multipart/form-data"
}

/// Extension to conform to `APIEndpointProtocol`.
extension APIEndpoint: APIEndpointProtocol {
    /// API version used by endpoints.
    var apiVersion: APIVersion {
        .v1
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
        switch self {
        case .uploadImage:
            return [Constants.contentTypeHeader: Constants.multipartFormDataContentType]
        case .getPosts, .createPost:
            return [:]
        }
    }
    
    /// Request URL parameters.
    var urlParams: [String: any CustomStringConvertible] {
        return [:]
    }
    
    /// Request body data.
    var body: Data? {
        switch self {
        case .createPost(let postDTO):
            return postDTO.toJSONData()
        case .uploadImage(let data, let fileName, let mimeType):
            let boundary = UUID().uuidString
            let multipartData = MultipartFormData(
                boundary: boundary,
                fileData: data,
                fileName: fileName,
                mimeType: mimeType.asString,
                parameters: [:]
            )
            return multipartData.asHttpBodyData
        case .getPosts:
            return nil
        }
    }
}
