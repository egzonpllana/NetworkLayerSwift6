//
//  HomeViewModel.swift
//
//  Created by Egzon Pllana.
//

import UIKit
import EventHorizon

final class HomeViewModel: HomeViewModelProtocol {
    
    // MARK: - Publishers -
    @Published var posts: [PostDTO] = []
    @Published var uploadProgress: Double = 0.0

    // MARK: - Properties -
    private let postsRepositoryUseCase: any PostsRepositoryUseCaseProtocol

    // MARK: - Initialization -
    init(
        postsRepositoryUseCase: any PostsRepositoryUseCaseProtocol = PostsRepositoryUseCase()
    ) {
        self.postsRepositoryUseCase = postsRepositoryUseCase
    }
    
    // MARK: - Methods -
    @discardableResult
    func getPosts() async throws -> [PostDTO] {
        self.posts = try await postsRepositoryUseCase.getPosts()
        return posts
    }
    
    func createPost() async throws {
        try await postsRepositoryUseCase.createPost()
    }
    
    func uploadImage() async throws {
        guard let image = UIImage(named: PostConstants.smallImageName),
              let data = image.jpegData(compressionQuality: 1.0) else {
            return
        }
        
        // Create the progress delegate inline.
        let progressDelegate = UploadProgressDelegate { [weak self] progress in
            // Update progress on the main thread.
            Task { @MainActor in
                self?.uploadProgress = progress
            }
        }
        
        // Pass the progress delegate to the upload method.
        // Note: current free API that we use do not support uploading multi part data, it will report the 503 status code.
        try await postsRepositoryUseCase.uploadImage(
            data: data,
            fileName: PostConstants.imageName,
            mimeType: ImageMimeType.png.asString,
            progressDelegate: progressDelegate
        )
    }
}
