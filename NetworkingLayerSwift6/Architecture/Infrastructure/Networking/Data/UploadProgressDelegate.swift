//
//  UploadProgressDelegate.swift
//
//  Created by Egzon Pllana.
//

import Foundation

/// A protocol to handle upload progress with URLSession tasks.
protocol UploadProgressDelegateProtocol: URLSessionTaskDelegate, Sendable { }

/// A delegate class for handling upload progress.
final class UploadProgressDelegate: NSObject, UploadProgressDelegateProtocol {

    /// A closure to handle the progress updates. This closure will be called on the main thread.
    private let progressHandler: (@Sendable (Double) -> Void)?
    
    /// Initializes the delegate with a progress handler.
    ///
    /// - Parameter progressHandler: A closure that will be called to handle progress updates.
    init(progressHandler: (@Sendable (Double) -> Void)?) {
        self.progressHandler = progressHandler
    }
    
    /// This method is called by the URLSession whenever data is sent during an upload task.
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        progressHandler?(progress)
    }
}
