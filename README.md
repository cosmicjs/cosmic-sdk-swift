<a href="https://app.cosmicjs.com/signup">
  <img src="https://imgix.cosmicjs.com/7d4c82a0-589d-11ee-8d99-6566412c38cc-GitHub.png?mask=corners&w=2000&auto=format&corner-radius=24,24,24,24" alt="Cosmic dashboard darkmode" />
</a>

# CosmicSDKSwift

A pure Swift interpretation of the Cosmic SDK for use in Swift and SwiftUI projects.

## About this project

This project is heavily inspired by our [JavaScript SDK](https://github.com/cosmicjs/cosmic-sdk-js) and [Adam Rushy's OpenAISwift](https://github.com/adamrushy/OpenAISwift/tree/main).

Having built multiple Cosmic-powered SwiftUI apps, it felt time to provide a smart SDK that mapped as closely to our JavaScript SDK without moving away from common Swift conventions.

[Cosmic](https://www.cosmicjs.com/) is a [headless CMS](https://www.cosmicjs.com/headless-cms) (content management system) that provides a web dashboard to create content and an API toolkit to deliver content to any website or application. Nearly any type of content can be built using the dashboard and delivered using this SDK.

[Get started free →](https://app.cosmicjs.com/signup)

## Install

### Swift Package Manager

You can use Swift Package Manager to integrate the SDK by adding the following dependency in the `Package.swift` file or by adding it directly within Xcode.

`.package(url: "https://github.com/cosmicjs/cosmic-sdk-swift.git", from: "1.0.0")`

## Usage

Import the framework in your project:

`import CosmicSDK`

You can get your API access keys by going to Bucket Settings > API Access in the [Cosmic dashboard](https://app.cosmicjs.com/login).

### Testing Your Connection

If you're experiencing issues, you can test your connection first:

```swift
// Test basic connection
do {
    let response = try await cosmic.testConnection()
    print("Connection successful: \(response)")
} catch {
    print("Connection failed: \(error)")
}
```

### Common Issues

1. **HTML Response Instead of JSON**: This usually means authentication failed

   - Check your bucket slug and read key
   - Ensure your read key has the correct permissions
   - Verify the bucket exists and is accessible

2. **Object Types Not Found**: Make sure the object types exist in your bucket

   - Check your Cosmic dashboard for available object types
   - Object type names are case-sensitive

3. **Network Issues**: Ensure your app has internet connectivity

```swift
let cosmic = CosmicSDKSwift(
    .createBucketClient(
        bucketSlug: BUCKET,
        readKey: READ_KEY,
        writeKey: WRITE_KEY
    )
)
```

To see all the available methods, you can look at our [JavaScript implementation](https://www.cosmicjs.com/docs/api/) for now. This project is not at feature parity or feature complete, but the methods listed below are.

From the SDK you can create your own state to hold your results, map a variable of any name to an array of type `Object` which is defined in our [model structure](https://www.cosmicjs.com/docs/api/objects#the-object-model). This is a singular `Object` that reflects any content model you create.

## Modern Swift Support

The SDK now supports both completion handlers (for backward compatibility) and modern async/await patterns. Choose the style that best fits your project.

## Metadata Access

The SDK now provides flexible metadata access with support for both the new dictionary format and legacy array format from the Cosmic API.

### Clean & Intuitive Access

The new API provides the cleanest possible syntax for metadata access:

```swift
// Direct comparisons - no casting needed!
if user.metadata?.is_premium == true {
    // Premium user logic
}

if user.metadata?.name == "John Doe" {
    // Name matches
}

// Works in conditionals
guard product.metadata?.in_stock == true else {
    return
}

// When you need to store values, use typed accessors
let name = user.metadata?.name.string
let age = user.metadata?.age.int
let tags = user.metadata?.tags.array(of: String.self)
```

### Three Ways to Access Metadata

```swift
// 1. Direct comparison (cleanest for conditionals)
if event.metadata?.is_virtual == true { }

// 2. Typed accessors (when you need the value)
let price = product.metadata?.price.double

// 3. Nested access (for complex structures)
let city = user.metadata?.address.city.string
```

Available type accessors:

- `.string` - String values
- `.int` - Integer values
- `.double` - Double/Float values
- `.bool` - Boolean values
- `.array(of:)` - Typed arrays
- `.dictionary(keyType:valueType:)` - Typed dictionaries
- `.raw` - Access raw value for custom types
- `.exists` - Check if field exists

### Real-World Examples

```swift
// Fetch a user object
let result = try await cosmic.findOne(type: "users", id: userId)
let user = result.object

// Direct comparisons - the cleanest syntax!
if user.metadata?.is_premium == true {
    print("Welcome, premium user!")
}

if user.metadata?.account_type == "enterprise" {
    enableEnterpriseFeatures()
}

// When you need to store values
let name = user.metadata?.name.string
let email = user.metadata?.email.string
let credits = user.metadata?.credits.int

// Nested object access
let city = user.metadata?.address.city.string
let country = user.metadata?.address.country.string

// Arrays with type safety
if let roles = user.metadata?.roles.array(of: String.self) {
    print("User roles: \(roles.joined(separator: ", "))")
}

// Check field existence
if user.metadata?.premium_expires.exists {
    // Handle premium expiration
}
```

### Alternative Access Methods

```swift
// Method 1: Using metafieldValue (returns AnyCodable)
let nameValue = user.metafieldValue(for: "name")?.value as? String

// Method 2: Using metafieldsDict
if let metadata = user.metafieldsDict {
    let name = metadata["name"]?.value as? String
    let email = metadata["email"]?.value as? String
}

// Method 3: For legacy support - access as array
if let fields = user.metafields {
    for field in fields {
        print("\(field.key): \(field.value?.value ?? "nil")")
    }
}
```

### SwiftUI Example

```swift
struct ProductView: View {
    let product: Object

    var body: some View {
        VStack {
            // Direct usage in SwiftUI views
            if product.metadata?.featured == true {
                Badge("Featured")
                    .foregroundColor(.yellow)
            }

            Text(product.metadata?.name.string ?? "Unknown Product")
                .font(.title)

            if let price = product.metadata?.price.double {
                Text("$\(price, specifier: "%.2f")")
                    .font(.headline)
            }

            // Conditional rendering based on stock
            if product.metadata?.in_stock == true {
                Button("Add to Cart") {
                    addToCart()
                }
            } else {
                Text("Out of Stock")
                    .foregroundColor(.gray)
            }

            // Display tags if available
            if let tags = product.metadata?.tags.array(of: String.self) {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            TagView(tag: tag)
                        }
                    }
                }
            }
        }
    }
}
```

### Creating/Updating Objects with Metadata

```swift
// Create new object with metadata
let response = try await cosmic.insertOne(
    type: "products",
    title: "Premium Subscription",
    metadata: [
        "price": 99.99,
        "currency": "USD",
        "features": ["Ad-free", "Priority support", "Advanced analytics"],
        "is_featured": true,
        "billing": [
            "cycle": "monthly",
            "trial_days": 14
        ]
    ]
)

// Update existing object metadata
try await cosmic.updateOne(
    type: "products",
    id: productId,
    metadata: [
        "price": 79.99,  // Update price
        "sale_ends": "2024-12-31T23:59:59Z"
    ]
)
```

### [Find](https://www.cosmicjs.com/docs/api/objects#get-objects)

**Using Async/Await (Recommended):**

```swift
@State var objects: [Object] = []

Task {
    do {
        let result = try await cosmic.find(type: TYPE)
        self.objects = result.objects
    } catch {
        print("Error: \(error)")
    }
}
```

**Using Completion Handlers:**

```swift
@State var objects: [Object] = []

cosmic.find(type: TYPE) { results in
    switch results {
    case .success(let result):
        self.objects = result.objects
    case .failure(let error):
        print(error)
    }
}
```

With optional props, limit, sorting and status parameters:

**Async/Await:**

```swift
let result = try await cosmic.find(
    type: TYPE,
    props: "metadata.image.imgix_url,slug",
    limit: 10,  // Now accepts Int instead of String
    sort: .random,
    status: .any  // Query for both published and draft objects
)
self.objects = result.objects
```

**Completion Handler:**

```swift
cosmic.find(
    type: TYPE,
    props: "metadata.image.imgix_url,slug",
    limit: 10,
    sort: .random,
    status: .any
) { results in
    switch results {
    case .success(let result):
        self.objects = result.objects
    case .failure(let error):
        print(error)
    }
}
```

### [Find One](https://www.cosmicjs.com/docs/api/objects#get-a-single-object-by-id)

**Async/Await:**

```swift
@State private var object: Object?

do {
    let result = try await cosmic.findOne(type: TYPE, id: objectId)
    self.object = result.object
} catch {
    print("Error: \(error)")
}
```

**Completion Handler:**

```swift
cosmic.findOne(type: TYPE, id: objectId) { results in
    switch results {
    case .success(let result):
        self.object = result.object
    case .failure(let error):
        print(error)
    }
}
```

You can't initialize a single Object with a specific type, so instead, mark as optional and handle the optionality accordingly.

```swift
if let object = object {
    Text(object.title)
}
```

### [Insert One](https://www.cosmicjs.com/docs/api/objects#create-an-object)

`.insertOne()` adds a new Object to your Cosmic Bucket. Use this for adding a new Object to an existing Object Type.

**Async/Await:**

```swift
do {
    let response = try await cosmic.insertOne(
        type: TYPE,
        title: "New Object Title"
    )
    print("Created successfully: \(response.message ?? "")")
} catch {
    print("Error: \(error)")
}
```

**Completion Handler:**

```swift
cosmic.insertOne(
    type: TYPE,
    title: "New Object Title"
) { results in
    switch results {
    case .success(let response):
        print("Created successfully")
    case .failure(let error):
        print(error)
    }
}
```

With optional props for content, metadata and slug:

**Async/Await:**

```swift
let response = try await cosmic.insertOne(
    type: TYPE,
    title: "New Product",
    slug: "new-product",
    content: "Product description here",
    metadata: [
        "price": 49.99,
        "sku": "PROD-001",
        "in_stock": true,
        "categories": ["Electronics", "Gadgets"]
    ]
)
print("Created object with ID: \(response.message ?? "")")
```

**Completion Handler:**

```swift
cosmic.insertOne(
    type: TYPE,
    title: "New Product",
    content: "Product description",
    metadata: ["key": "value"],
    slug: "new-product"
) { results in
    switch results {
    case .success(let response):
        print("Created successfully")
    case .failure(let error):
        print(error)
    }
}
```

### [Update One](https://www.cosmicjs.com/docs/api/objects#update-an-object)

When using `.updateOne()` you can update an Object's metadata by passing the optional metadata dictionary with one, or many, `key:value` pairs.

**Async/Await:**

```swift
do {
    let response = try await cosmic.updateOne(
        type: TYPE,
        id: objectId,
        title: "Updated Title",
        metadata: ["last_updated": Date().ISO8601Format()]
    )
    print("Updated successfully")
} catch {
    print("Error: \(error)")
}
```

**Completion Handler:**

```swift
cosmic.updateOne(
    type: TYPE,
    id: objectId,
    title: "Updated Title",
    content: "New content",
    metadata: ["key": "value"],
    status: .published
) { results in
    switch results {
    case .success(_):
        print("Updated successfully")
    case .failure(let error):
        print(error)
    }
}
```

### [Delete One](https://www.cosmicjs.com/docs/api/objects#delete-an-object)

**Async/Await:**

```swift
do {
    let response = try await cosmic.deleteOne(type: TYPE, id: objectId)
    print("Deleted successfully")
} catch {
    print("Error: \(error)")
}
```

**Completion Handler:**

```swift
cosmic.deleteOne(type: TYPE, id: objectId) { results in
    switch results {
    case .success(_):
        print("Deleted successfully")
    case .failure(let error):
        print(error)
    }
}
```

Depending on how you handle your data, you will have to account for `id` being a required parameter in the API.

## New Features

### Scheduled Publishing

You can now schedule objects to be published or unpublished at specific dates:

```swift
// Schedule publish date
cosmic.insertOne(
    type: "posts",
    title: "Holiday Sale",
    publish_at: "2024-12-25T00:00:00.000Z"  // ISO 8601 format
) { ... }

// Schedule unpublish date
cosmic.updateOne(
    type: "events",
    id: eventId,
    title: "Limited Time Offer",
    unpublish_at: "2024-12-31T23:59:59.000Z"
) { ... }
```

Note: Objects with `publish_at` or `unpublish_at` dates are automatically saved as drafts.

### Query Any Status

Use `.any` status to query both published and draft objects:

```swift
cosmic.find(
    type: "posts",
    status: .any  // Returns both published and draft objects
) { ... }
```

## Migration Guide

### Limit Parameter Change

The `limit` parameter now accepts `Int` instead of `String`. If you have existing code using String limits:

```swift
// Old code
cosmic.find(type: "posts", limit: "10") { ... }

// New code
cosmic.find(type: "posts", limit: 10) { ... }

// If you have a String variable
let stringLimit = "10"
cosmic.find(type: "posts", limit: Int(stringLimit) ?? 10) { ... }
```

## License

The MIT License (MIT)

Copyright (c) 2024 CosmicJS

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
