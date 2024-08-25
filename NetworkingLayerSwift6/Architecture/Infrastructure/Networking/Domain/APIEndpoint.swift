//
//  APIEndpoint.swift
//
//  Created by Egzon Pllana.
//

import Foundation

enum APIEndpoint {
    case getPosts
    case createPost(PostDTO)
    case uploadImage(data: Data, fileName: String, mimeType: ImageMimeType)
}
