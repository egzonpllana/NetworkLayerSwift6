# Building a generic, thread-safe Networking Layer in Swift 6

<img width="1013" alt="NetworkingLayerSwift6" src="https://github.com/user-attachments/assets/ba9b307f-f773-4135-85c0-55c78352944c">

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

___

### Concurrency 

Concurrency is about performing multiple tasks at the same time. In programming, it means you can run different pieces of code simultaneously rather than one after the other. This is especially useful for tasks that can be done independently, like downloading files, processing data, or handling user inputs. In Swift, you manage concurrency using:

* **Grand Central Dispatch** (GCD): A way to execute code on different threads. You can schedule tasks to run asynchronously on various queues (e.g., background queue for non-UI work, main queue for UI updates).
    
* **Swift Concurrency** (async/await): A more modern approach introduced in Swift 5.5, which simplifies writing asynchronous code. With async/await, you can write code that looks synchronous but performs tasks in the background.
    

#### Thread Safety

Thread safety ensures that your code works correctly when multiple threads access the same data at the same time. If your code is not thread-safe, you might run into problems like:

* **Data races**: When two or more threads try to read and write the same data simultaneously, leading to unpredictable results.
    
* **Crashes**: When data is accessed in an unexpected state due to concurrent modifications. 
    

To make code thread-safe, you need to protect shared data so that only one thread can access or modify it at a time. This can be done using synchronization mechanisms like locks, serial queues, or using thread-safe data structures. In Swift, you use:

* `Serial Queues`: Ensure that tasks run one after another, thus preventing concurrent access.
    
* `@MainActor` or DispatchQueue.main: Ensures that code accessing UI elements or other main-thread-bound resources is run on the main thread.

```swift
// Using a serial queue to ensure thread safety
let queue = DispatchQueue(label: "com.example.queue")
queue.async {
 // Only one thread will access this block at a time
 self.sharedResource += 1
}
```

Concurrency is about running multiple tasks simultaneously to improve performance and responsiveness. Thread Safety is about ensuring that shared data is accessed in a way that prevents issues when multiple threads are involved. In Swift and Apple development, managing both concurrency and thread safety is crucial to building efficient and reliable applications.

#### @preconcurrency attribute

`@preconcurrency` is an attribute in Swift used to mark a type, function, or declaration as being from a pre-concurrency codebase, which means it was written before Swift's concurrency model (introduced in Swift 5.5) was available. This attribute helps the Swift compiler to relax some of its stricter concurrency checks for backward compatibility.

```swift
@preconcurrency
class LegacyClass {
    var data: SomeType
    init(data: SomeType) {
        self.data = data
    }
}
```

When you use `@preconcurrency`, you're essentially telling the compiler that the code or API you're working with might not conform to Swift's new concurrency rules but that it's still safe to use in a concurrent context.

**Common Use Cases for @preconcurrency**

1.  **Legacy Code Interoperability**: If you’re working with code (especially from third-party libraries) that was written before Swift’s concurrency model, you can use @preconcurrency to prevent the compiler from enforcing strict concurrency checks that didn't exist when the code was originally written.
    
2.  **Class and Protocol Conformance**: You might apply `@preconcurrency` when you need to conform to a protocol or work with a class that hasn't been updated for concurrency but is being used in a concurrent environment.
    
3.  **Imported C and Objective-C APIs**: When importing APIs from C or Objective-C that predate Swift’s concurrency, you might mark their types or methods as `@preconcurrency` to allow their use without having to retrofit them for Sendable conformance or actor isolation.
    

**Important Considerations**

* **Backward Compatibility**: `@preconcurrency` is mainly useful when you're transitioning code to Swift’s concurrency model but still have to interact with legacy code that doesn’t adhere to the new concurrency guarantees.
    
* **Compiler Relaxation**: It doesn’t make your code thread-safe; it simply relaxes some of the stricter concurrency rules enforced by the compiler. You need to be cautious when using it, as it may lead to potential concurrency issues if the code isn’t properly designed for concurrent execution.
    

### Sendable Protocol

Since Swift 6 emphasizes safe concurrency, ensuring that types conform to Sendable helps guarantee that data passed across concurrency boundaries is safely shared. You’ve already included Sendable where appropriate so that part is good. However, you should ensure that all components involved in the async methods also conform to Sendable, as they might be passed between concurrent tasks.

#### **Sendable Conformance**

For a class to conform to `Sendable`, it must guarantee that its state is safely shared across threads, meaning:

* Its properties must either be `Sendable` themselves or designed so that there is no race condition when accessed concurrently.
    
* In some cases, using `@unchecked` Sendable is necessary if you’re sure the class is safe but the compiler can’t guarantee it due to the class’s design (e.g., mutable state protected by locks), so this responsibility is not in the hands of the developer and not to the compiler checks.

```swift
// The use of NSLock ensures thread safety when accessing 
// or modifying the count property.
class Counter: Sendable {
    private var count: Int = 0
    private let lock = NSLock()
    
    init(count: Int) {
        self.count = count
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }

    func getCount() -> Int {
        lock.lock()
        let value = count
        lock.unlock()
        return value
    }
}
```
In Swift, certain types are automatically considered Sendable and don't require you to manually conform them to the Sendable protocol. This is because they are inherently safe to use across threads due to their immutability or specific guarantees.

Here are some types that do **not** require manual Sendable conformance:

1\. Value types like structs and enums — Immutable value types are safe to share across threads. Exampletypes: Int, Double, Bool, String, Array, Dictionary, Set, etc.

2\. Standard types **—** Types such as String, Int, Double, and Bool are automatically Sendable.

3\. Types that conform to the Sendable protocol by default — Foundation types like Date, URL, and UUID are already Sendable.

4\. Immutable class types — final classes that are guaranteed to have no mutable state may also be Sendable without explicit conformance.

#### @unchecked Sendable 

`@unchecked` Sendable is used when you want to tell the Swift compiler that a class or type is safe to be sent across threads, even if the compiler can't verify that it's actually safe. This attribute is necessary when the type doesn't automatically conform to Sendable but you're confident that your implementation is thread-safe. Example of a class that uses synchronization to ensure thread safety:

```swift
final class MyClass: @unchecked Sendable {
    private var value: Int = 0
    private let queue = DispatchQueue(label: "com.myapp.syncQueue")

    func updateValue(_ newValue: Int) {
        queue.sync {
            self.value = newValue
        }
    }

    func getValue() -> Int {
        return queue.sync { value }
    }
}
```

**Why @unchecked Sendable?**By default, the compiler performs strict checks to ensure that types marked as Sendable can safely be transferred across threads. These checks ensure that:

* Mutable state isn’t accidentally shared between threads without proper synchronization.
    
* All properties of the type conform to Sendable.
    

However, if you have a type that contains non-Sendable properties or uses a class (which is reference type and mutable by default), the compiler won't automatically consider it safe for concurrency.

```swift
struct MyStruct: Sendable {
    // A property that is not inherently Sendable
    @unchecked var nonSendableProperty: SomeType
}
```

You use @unchecked Sendable when:

* You’re certain that your type is thread-safe.
    
* The compiler can’t confirm thread safety but you have applied your own synchronization or use only immutable data.
    

Using @unchecked Sendable bypasses the compiler's checks, so you must be careful to ensure the code is indeed safe. If not, you could introduce subtle concurrency bugs.

### When to Use @MainActor

* The code in the methods interacts directly with the UI (e.g., updating UI elements like lists, labels, or progress bars).
    
* The protocol or its methods are designed to be run on the main thread for thread safety, especially if you deal with UI updates or other main-thread-sensitive operations (such as updating `@Published` properties in ObservableObject).
    

Additionally, If most of the properties and methods in your view model involve UI updates, keeping `@MainActor` at the protocol level simplifies the code. 

```swift
@MainActor
protocol HomeViewModelProtocol: ObservableObject { ... }
```

However, if you’re doing a lot of background work (e.g., networking or data processing) and only occasionally need to update the UI, I’d recommend selective use of `@MainActor` on the properties and methods that actually need it. This way, you get the best of both worlds: concurrency where possible and main thread safety for UI updates.

#### Reasons to use `@MainActor`

*  **UI-Related Protocol**: If HomeViewModelProtocol involves properties or methods that interact with the UI (e.g., updating views, binding `@Published` properties), you must ensure that these interactions are performed on the main thread. The `@MainActor` attribute guarantees this behavior by automatically routing calls to the main thread.
    
* **Thread Safety**: By marking a protocol with `@MainActor`, any conforming type (e.g., a view model) ensures that all of its properties and methods are always accessed on the main thread, avoiding thread-safety issues that could occur when data is updated from different threads simultaneously.
    
* **Automatic Thread Hopping**: The `@MainActor` attribute handles moving execution to the main thread for you, even if the caller is on a background thread. This simplifies your code, ensuring that your UI remains responsive without manually hopping to the main thread every time you update the UI.
    
* **Concurrency Model Compatibility**: Swift’s structured concurrency model expects code that interacts with the UI to be marked with `@MainActor`. If you omit it and your view model is used in a concurrent context, you’ll likely run into thread-related issues or crashes.
    

### The end 🏁

I hope you found this article both engaging and useful for your projects. Personally, I have successfully applied these techniques in my own projects and technical challenges without any issues. You can customize and extend the methods as needed while utilizing generics to maintain code efficiency. Asynchronous programming with Sendable and async/await is likely to become a standard practice in the near future for any Apple platform.

Thank you for following along. I encourage you to share any feedback or suggestions you may have about this Networking Layer. Together, we can continue to enhance and refine it.

### Resources

* [MainActor](https://developer.apple.com/documentation/Swift/MainActor?changes=__7) _by Apple_
* [MainActor](https://www.avanderlee.com/swift/mainactor-dispatch-main-thread/) _by Avanderlee_
* [Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) _by Apple_ 
* [Async await by](https://www.avanderlee.com/swift/async-await/) _by Avanderlee_
* [Sendable protocol](https://developer.apple.com/documentation/swift/sendable#) _by Apple_
* [Sendable and @Sendable protocol](https://www.avanderlee.com/swift/sendable-protocol-closures/) _by Avanderlee_
* [Generics](https://www.hackingwithswift.com/plus/intermediate-swift/understanding-generics-part-1) _by HackingWithSwift_

### Medium article:

https://medium.com/@egzonpllana/building-a-generic-thread-safe-networking-layer-in-swift-6-927fa1d0cce8

### Let’s Connect

* LinkedIn: [https://www.linkedin.com/in/egzon-pllana](https://www.linkedin.com/in/egzon-pllana)
    
* GitHub: [https://github.com/egzonpllana](https://github.com/egzonpllana)
