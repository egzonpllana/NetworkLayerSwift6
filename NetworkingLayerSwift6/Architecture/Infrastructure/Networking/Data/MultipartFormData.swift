//
//  MultipartFormData.swift
//
//  Created by Egzon Pllana.
//

import Foundation

/// A model representing multipart form data configuration.
struct MultipartFormData {
    /// Boundary string used to separate parts.
    let boundary: String
    
    /// Data of the file to upload.
    let fileData: Data
    
    /// Name of the file.
    let fileName: String
    
    /// MIME type of the file.
    let mimeType: String
    
    /// Parameters to include in the multipart form data.
    let parameters: [String: String]
 
}

extension MultipartFormData {

    /// Creates multipart form data body.
    var asHttpBodyData: Data {
        var body = Data()
        
        // Add parameters
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}
