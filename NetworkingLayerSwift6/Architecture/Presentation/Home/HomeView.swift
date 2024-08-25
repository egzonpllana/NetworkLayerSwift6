//
//  ContentView.swift
//
//  Created by Egzon Pllana.
//

import SwiftUI

struct HomeView: View {

    // MARK: - Properties -
    @StateObject private var viewModel = HomeViewModel()
    
    // MARK: - View -
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
            VStack {
                Text("Posts: \(viewModel.posts.count)")
                Text("Upload progress: \(String(format: "%.0f%%", viewModel.uploadProgress * 100))")
            }
            .padding()
        }
        .padding()
        .onAppear {
            // Enable any for testing.
            // -----------------------
            getPosts()
            // createPost()
            // uploadImage()
        }
    }

    // MARK: - Methods -
    private func getPosts() {
        Task {
            try await viewModel.getPosts()
            print("[Task] Get posts finished.")
        }
    }
    
    private func createPost() {
        Task {
            try await viewModel.createPost()
            print("[Task] Create post finished.")
        }
    }

    private func uploadImage() {
        Task {
            try await viewModel.uploadImage()
            print("[Task] Upload image finished.")
        }
    }
}

#Preview {
    HomeView()
}
