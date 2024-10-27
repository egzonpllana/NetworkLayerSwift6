# Building a generic, thread-safe Networking Layer in Swift 6

![NetworkingLayerSwift6](https://github.com/user-attachments/assets/ef2f41d3-498c-4de3-a4de-2dd7427dbdcf)

___

In this article, we will build a networking layer that meets the thread safety requirements introduced in **Swift 6**, using Swift features such as async-await, Sendable, MainActor, etc. While many of these features appeared in Swift 5.5, they are becoming more important, especially in Swift 6. 

To make sure your project aligns with these changes, select your project in Xcode, then go to your target’s Build Settings > under “All & Combined,” search for “Swift 6” or find the “Swift Compiler — Upcoming Features” section and enable these settings as you want and XCode will throw errors or warnings.

> There will be no future in Swift development without async await and Sendable protocol.

The networking layer we will build will use the latest Swift concurrency APIs and thread-safe methods to avoid multi-threading issues or crashes. The key components of this networking layer will be the APIEndpoint protocol and the APIClient protocol. This will let us seamlessly execute network calls and obtain results with just one line of code⚡️.  

```swift
// get
let posts: [PostDTO] = try await apiClient.request(APIEndpoint.getPosts)

// post
let newPost: PostDTO = .init()
try await apiClient.requestVoid(APIEndpoint.createPost(newPost))

// multi-part request
try await apiClient.requestWithProgress(APIEndpoint.uploadImage(...),
          progressDelegate: UploadProgressDelegateProtocol)
```

#### APIEndpointProtocol

APIEndpointProtocol defines the essential components of an API endpoint, such as HTTP methods, paths, base URLs, headers, URL parameters, and request bodies. It ensures a consistent and clear approach to constructing network requests through its urlRequest property, which assembles a URLRequest by combining these elements.

```swift
protocol APIEndpointProtocol {
    /// HTTP method used by the endpoint.
    var method: HTTPMethod { get }
    
    /// Path for the endpoint.
    var path: String { get }
    
    /// Base URL for the API.
    var baseURL: String { get }
    
    /// Headers for the request.
    var headers: [String: String] { get }
    
    /// URL parameters for the request.
    var urlParams: [String: any CustomStringConvertible] { get }
    
    /// Body data for the request.
    var body: Data? { get }
    
    /// URLRequest representation of the endpoint.
    var urlRequest: URLRequest? { get }
    
    /// API version used by the endpoint.
    var apiVersion: APIVersion { get }
}

/// Endpoints
enum APIEndpoint: APIEndpointProtocol {
    case getPosts
    case createPost(PostDTO)
    case uploadImage(data: Data, fileName: String, mimeType: ImageMimeType)

    // Define all properties required by the protocol,
    // matching your backend API.
}
```

#### APIClientProtocol

APIClientProtocol defines the contract for making network requests and handling responses in a structured way. It abstracts away the complexity of sending HTTP requests and decoding responses, allowing you to focus on the data and logic. The protocol supports asynchronous operations and is designed to work with any type that conforms to Codable and Sendable.

**Key methods include:**

* `request(:decoder:)`: Sends a request using URLSession, decodes the response into a specified type, and returns the result.
    
* `requestVoid(:)`: Sends a request that provides no response data.
    
* `requestWithAlamofire(:decoder:)`: Sends a request using Alamofire and decodes the response.
    
* `requestWithProgress(:progressDelegate:)`: Fetches raw data with optional upload progress tracking.

```swift
func request<T: Decodable & Sendable>(
    _ endpoint: any APIEndpointProtocol,
    decoder: JSONDecoder
) async throws -> T {
    guard let request = endpoint.urlRequest else {
        throw APIClientError.invalidURL
    }
    
    // Perform the network request and decode the data
    let data = try await performRequest(request)
    do {
        return try decoder.decode(T.self, from: data)
    } catch {
        // Handle decoding errors
        throw APIClientError.decodingFailed(error)
    }
}
```

**Parameters**

* `endpoint` any APIEndpointProtocol: This parameter represents the API endpoint that contains the URL request configuration. The any keyword allows for any type that conforms to APIEndpointProtocol. This protocol typically includes properties or methods to provide the URL request needed for the network call.
    
* `decoder`: JSONDecoder: This parameter is an instance of JSONDecoder, used to decode the JSON response into a Swift model. The JSONDecoder converts JSON data into instances of types that conform to the Decodable protocol.
    

**Generic Type T**

* `T: Decodable & Sendable`: is a generic type that must conform to both Decodable and Sendable protocols.Decodable: This protocol allows the type to be initialized from JSON data. It ensures that the type can be created from a serialized JSON format.
    
* `Sendable`: This protocol indicates that the type can be safely used in concurrent code. It’s essential for types that will be used across different threads or tasks, ensuring that they don’t cause data races or concurrency issues.
    

**Functionality**

* **URL Request Validation**: The method first checks if the endpoint provides a valid URL request. If not, it throws an APIClientError.invalidURL, indicating a configuration issue. 
    
* **Perform Network Request**: It uses performRequest to execute the network call and retrieve the response data asynchronously. This method is likely defined elsewhere and handles the actual communication with the server.
    
* **Decode Response Data**: The method attempts to decode the received data into the generic type T using the decoder. If decoding fails, it throws an APIClientError, providing details about the failure.
    

The APIClient also has additional methods for different use cases

* Request Void method, in cases when we only are interested in the request status (success or failure).
    
* Request through Alamofire, which I do not recommend, but just in case you are a fan of our beloved framework from the past.
    
* Request method that we want to get the request-response Data, in case we need to decode it differently.
    

#### Real app implementation

In this example, HomeViewModel leverages APIClient to handle network requests and update its posts property with the data fetched from an API.
```swift
class HomeViewModel: ObservableObject {
   @Published var posts: [PostDTO] = []
   private let apiClient: APIClient = APIClient()

  func getPosts() async throws {
       posts = try await apiClient.request(APIEndpoint.getPosts)
   }
}
```
* The class is marked as `ObservableObject`, which allows SwiftUI views to observe changes in its properties.
    
* The `@Published` modifier is used on the posts property so that the UI automatically updates whenever the value changes.
    
* The `apiClient` is an instance of APIClient, which conforms to APIClientProtocol and handles all network interactions.
    

The `getPosts()` method demonstrates how APIClient interacts with an API endpoint:

* apiClient.request(APIEndpoint.getPosts) sends a request to the getPosts endpoint, using the `request(_:decoder:)` method from APIClientProtocol.
    
* The result is decoded into an array of `PostDTO` and then assigned to the posts property.
    
* This operation is performed asynchronously using Swift’s `async/await`, making it efficient and non-blocking.
    

In this example, HomeView is a SwiftUI view that displays the number of posts fetched from an API using HomeViewModeland APIClient.

```swift
struct HomeView: View {
 @StateObject private var viewModel = HomeViewModel()
 
 var body: some View {
    Text("Posts count: \(viewModel.posts.count)")
 }
 .onAppear {
    Task {
        try await viewModel.getPosts()
    }
 }
}
```

* HomeView uses `@StateObject` to create and manage the viewModel instance, which is responsible for handling data fetching.
    
* The body of the view contains a simple Text element that displays the count of posts from the viewModel.
    

In the `.onAppear` modifier:

* A Task block is created to perform the asynchronous viewModel.getPosts() call. This ensures that the posts are fetched when the view appears on the screen.
    
* Inside the task, `viewModel.getPosts()` is called asynchronously, requesting the API to retrieve posts via the APIClient. The posts array in HomeViewModel is updated when the data is successfully fetched, and the UI reflects the new data automatically due to the @Published property.

Isn’t this the most beautiful Networking layer you have ever seen? If yes, let's go an extra mile to understand concurrency and thread-safe techniques in Swift👇🚀
https://medium.com/p/5ccfdc0ca2b6

### The end 🏁

I hope you found this article both engaging and useful for your projects. Personally, I have successfully applied these techniques in my own projects and technical challenges without any issues. You can customize and extend the methods as needed while utilizing generics to maintain code efficiency. Asynchronous programming with Sendable and async/await is likely to become a standard practice in the near future for any Apple platform.

Thank you for following along. I encourage you to share any feedback or suggestions you may have about this Networking Layer. Together, we can continue to enhance and refine it.

### Resources

* [MainActor](https://developer.apple.com/documentation/Swift/MainActor?changes=__7) _by Apple_
* [Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) _by Apple_ 
* [Sendable protocol](https://developer.apple.com/documentation/swift/sendable#) _by Apple_

### Medium article:

https://medium.com/@egzonpllana/building-a-generic-thread-safe-networking-layer-in-swift-6-927fa1d0cce8

### Let’s Connect

* LinkedIn: [https://www.linkedin.com/in/egzon-pllana](https://www.linkedin.com/in/egzon-pllana)
    
* GitHub: [https://github.com/egzonpllana](https://github.com/egzonpllana)
