//
//  PostsRepositoryUseCase.swift
//
//  Created by Egzon Pllana.
//

import Foundation
import EventHorizon

/// Concrete implementation of `PostsRepositoryUseCaseProtocol` for managing post-related operations.
final class PostsRepositoryUseCase: PostsRepositoryUseCaseProtocol {

    private let postsRepository: any PostsRepositoryProtocol

    init(postsRepository: any PostsRepositoryProtocol = PostsRepository()) {
        self.postsRepository = postsRepository
    }

    func getPosts() async throws -> [PostDTO] {
        return try await postsRepository.getPosts()
    }

    func createPost() async throws {
        try await postsRepository.createPost()
    }

    func uploadImage(data: Data, fileName: String, mimeType: String, progressDelegate: (any UploadProgressDelegateProtocol)?) async throws {
        try await postsRepository.uploadImage(
            data: data,
            fileName: fileName,
            mimeType: mimeType,
            progressDelegate: progressDelegate
        )
    }
}
