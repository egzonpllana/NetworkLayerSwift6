//
//  PostDTO.swift
//
//  Created by Egzon Pllana.
//

import Foundation

/// A struct representing the data transfer object for a post.
struct PostDTO: Codable {
    let userId: Int
    let title: String
    let body: String
}

extension PostDTO {
    /// Converts the `PostDTO` data to JSON format for use in a request body.
    ///
    /// - Returns: A `Data` object representing the post data in JSON format, or `nil` if the conversion fails.
    func toJSONData() -> Data? {
        let jsonObject: [String: Any] = [
            "userId": userId,
            "title": title,
            "body": body
        ]
        return try? JSONSerialization.data(withJSONObject: jsonObject, options: [])
    }
}
