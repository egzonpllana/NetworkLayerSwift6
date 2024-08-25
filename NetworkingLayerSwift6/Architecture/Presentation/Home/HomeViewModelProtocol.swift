//
//  HomeViewModelProtocol.swift
//
//  Created by Egzon Pllana.
//

import Foundation

/// A protocol defining the interface for a Home ViewModel.
///
/// The `HomeViewModelProtocol` provides properties and methods for managing posts and uploading images.
///
/// - Conforms to: `MainActor`
/// - Requires: `ObservableObject` to support SwiftUI's data-binding and reactivity.
@MainActor
protocol HomeViewModelProtocol: ObservableObject, Sendable {
    
    /// A list of posts managed by the ViewModel.
    ///
    /// This property provides the current collection of posts.
    /// It is expected to be updated as posts are fetched or created.
    var posts: [PostDTO] { get }
    
    /// A read-only computed property for the upload progress.
    var uploadProgress: Double { get }
    
    /// Fetches a list of posts from the API.
    ///
    /// This method asynchronously retrieves posts from the API and returns them.
    ///
    /// - Returns: An array of `PostDTO` representing the fetched posts.
    /// - Throws: An error if the request fails or data cannot be parsed.
    @discardableResult
    func getPosts() async throws -> [PostDTO]
    
    /// Creates a new post.
    ///
    /// This method asynchronously creates a new post by sending data to the API.
    ///
    /// - Throws: An error if the creation request fails.
    func createPost() async throws
    
    /// Uploads an image to the API with progress tracking.
    ///
    /// This method asynchronously uploads an image to the API. It also supports progress tracking
    /// through a `progressDelegate`, if provided.
    ///
    /// - Throws: An error if the upload fails.
    func uploadImage() async throws
}
