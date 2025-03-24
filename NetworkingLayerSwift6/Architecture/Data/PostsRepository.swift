//
//  PostsRepository.swift
//
//  Created by Egzon Pllana.
//

import UIKit
import EventHorizon

enum PostConstants {
    static let defaultUserId = 1
    static let defaultTitle = "Title here"
    static let defaultBody = "Body here"
    static let smallImageName = "image-png.png"
    static let imageName = "image-name"
}

/// Concrete implementation of `PostsRepositoryProtocol` for managing posts and image uploads.
final class PostsRepository: PostsRepositoryProtocol {
    private let apiClient: any APIClientProtocol
    private typealias apiEndpoint = APIEndpointExample

    init(
        apiClient: any APIClientProtocol = APIClient(
            interceptors: Interceptors.example
        )
    ) {
        self.apiClient = apiClient
    }

    func getPosts() async throws -> [PostDTO] {
        let fetchedPosts: [PostDTO] = try await apiClient.request(apiEndpoint.getPosts)
        return fetchedPosts
    }

    func createPost() async throws {
        let newPost = PostDTO(
            userId: PostConstants.defaultUserId,
            title: PostConstants.defaultTitle,
            body: PostConstants.defaultBody
        )
        do {
            try await apiClient.request(apiEndpoint.createPost(newPost))
        } catch {
            log("Error: \(error)")
            throw error
        }
    }

    func uploadImage(
        data: Data,
        fileName: String,
        mimeType: String,
        progressDelegate: (any UploadProgressDelegateProtocol)? = nil
    ) async throws {
        let endPoint = apiEndpoint.uploadImage(
            data: data,
            fileName: fileName,
            mimeType: ImageMimeType(rawValue: mimeType) ?? .png
        )
        do {
            try await apiClient.request(
                endPoint,
                progressDelegate: progressDelegate
            )
        } catch {
            log("Error uploading image: \(error)")
            throw error
        }
    }
    
    private func log(_ string: String) {
        #if DEBUG
        print(string)
        #endif
    }
}
