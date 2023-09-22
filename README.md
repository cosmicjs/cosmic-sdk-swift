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

### [Find](https://www.cosmicjs.com/docs/api/objects#get-objects)

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

With optional props, limit, sorting and status parameters.

```swift
@State var objects: [Object] = []

cosmic.find(
    type: TYPE, 
    props: "metadata.image.imgix_url,slug", 
    limit: "10", 
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

```swift
@State private var object: Object?

cosmic.findOne(type: TYPE, id: object.id) { results in
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

```swift
cosmic.insertOne(
    type: TYPE, 
    id: object.id, 
    props: object.props, 
    title: object.title
    ) { results in
    switch results {
    case .success(_):
        print("Updated \(object.id)")
    case .failure(let error):
        print(error)
    }
}
```

With optional props for content, metadata and slug

```swift
cosmic.insertOne(
    type: TYPE, 
    id: object.id, 
    props: object.props, 
    title: object.title, 
    content: object.content, 
    metadata: ["key": "value"], 
    slug: object.slug
    ) { results in
    switch results {
    case .success(_):
        print("Inserted \(object.id)")
    case .failure(let error):
        print(error)
    }
}
```

### [Update One](https://www.cosmicjs.com/docs/api/objects#update-an-object)

When using `.updateOne()` you can update an Object's metadata by passing the optional metadata dictionary with one, or many, `key:value` pairs.

```swift
cosmic.updateOne(type: TYPE, id: object.id) { results in
    switch results {
    case .success(_):
        print("Updated \(object.id)")
    case .failure(let error):
        print(error)
    }
}
```

With optional props for title, content, metadata and status

```swift
cosmic.updateOne(
    type: TYPE, 
    id: object.id, 
    title: object.title, 
    content: object.content, 
    metadata: ["key": "value"], 
    status: .published
    ) { results in
    switch results {
    case .success(_):
        print("Updated \(object.id)")
    case .failure(let error):
        print(error)
    }
}
```

### [Delete One](https://www.cosmicjs.com/docs/api/objects#delete-an-object)

```swift
cosmic.deleteOne(type: TYPE, id: object.id) { results in
    switch results {
    case .success(_):
        print("Deleted \(object.id)")
    case .failure(let error):
        print(error)
    }
}
```

Depending on how you handle your data, you will have to account for `id` being a required parameter in the API.

## License

The MIT License (MIT)

Copyright (c) 2023 CosmicJS

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
