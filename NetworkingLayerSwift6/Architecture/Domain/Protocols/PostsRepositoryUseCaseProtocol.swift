//
//  PostsRepositoryUseCaseProtocol.swift
//
//  Created by Egzon Pllana.
//

import Foundation

/// Protocol defining the use case for managing post-related operations.
protocol PostsRepositoryUseCaseProtocol: Sendable {
    /// Retrieves posts using the `PostsRepository`.
    /// - Returns: An array of `PostDTO` objects.
    /// - Throws: An error if the service request fails.
    func getPosts() async throws -> [PostDTO]

    /// Creates a new post using the `PostsRepository`.
    /// - Throws: An error if the service request fails.
    func createPost() async throws

    func uploadImage(
        data: Data,
        fileName: String,
        mimeType: String,
        progressDelegate: (any UploadProgressDelegateProtocol)?
    ) async throws
}
