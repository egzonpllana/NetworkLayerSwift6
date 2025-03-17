//
//  PostsRepositoryProtocol.swift
//
//  Created by Egzon Pllana.
//

import Foundation
import EventHorizon

/// Protocol defining the operations for managing posts and uploading images.
protocol PostsRepositoryProtocol: Sendable {
    /// Fetches posts from the API.
    /// - Returns: An array of `PostDTO` objects.
    /// - Throws: An error if the request fails.
    func getPosts() async throws -> [PostDTO]

    /// Creates a new post with default values.
    /// - Throws: An error if the request fails.
    func createPost() async throws

    func uploadImage(
        data: Data,
        fileName: String,
        mimeType: String,
        progressDelegate: (any UploadProgressDelegateProtocol)?
    ) async throws
}
