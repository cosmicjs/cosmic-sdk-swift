//
//  CosmicSDK.swift
//
//
//  Created by Karl Koch on 19/09/2023.
//

import Foundation
#if canImport(FoundationNetworking) && canImport(FoundationXML)
import FoundationNetworking
import FoundationXML
#endif

public enum CosmicError: Error {
    case genericError(error: Error)
    case decodingError(error: Error)
}

// Type aliases to improve IDE autocomplete
public typealias CosmicStatus = CosmicEndpointProvider.Status
public typealias CosmicSorting = CosmicEndpointProvider.Sorting

// MARK: - String to Int conversion helper
// For backwards compatibility, if you have String limits in your code,
// you can convert them using: Int(yourStringLimit) ?? defaultValue
// Example: sdk.find(type: "posts", limit: Int("10") ?? 10)

/// CosmicSDKSwift provides a Swift interface to the Cosmic API.
///
/// This SDK requires:
/// - iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+
/// - Swift 5.5+
///
/// These requirements are due to the use of async/await features.
public class CosmicSDKSwift {
    fileprivate let config: Config

    /// Configuration object for the client
    public struct Config {
        
        /// Initialiser
        /// - Parameter session: the session to use for network requests.
        public init(baseURL: String, endpointPrivider: CosmicEndpointProvider, bucketSlug: String, readKey: String, writeKey: String, session: URLSession, authorizeRequest: @escaping (inout URLRequest) -> Void) {
            self.baseURL = baseURL
            self.endpointProvider = endpointPrivider
            self.authorizeRequest = authorizeRequest
            self.bucketSlug = bucketSlug
            self.readKey = readKey
            self.writeKey = writeKey
            self.session = session
        }
        let baseURL: String
        let endpointProvider: CosmicEndpointProvider
        let session: URLSession
        let authorizeRequest: (inout URLRequest) -> Void
        let bucketSlug: String
        let readKey: String
        let writeKey: String
        
        public static func createBucketClient(bucketSlug: String, readKey: String, writeKey: String) -> Self {
            .init(baseURL: "https://api.cosmicjs.com",
                  endpointPrivider: CosmicEndpointProvider(source: .cosmic),
                  bucketSlug: bucketSlug,
                  readKey: readKey,
                  writeKey: writeKey,
                  session: .shared,
                  authorizeRequest: { request in
                    // Only add Authorization header for non-GET requests
                    // GET requests use read_key in URL parameters
                    if request.httpMethod != "GET" {
                        request.setValue("Bearer \(writeKey)", forHTTPHeaderField: "Authorization")
                    }
            })
        }
    }
    
    public init(_ config: Config) {
        self.config = config
    }
    
    private func makeRequest(request: URLRequest, completionHandler: @escaping (Result<Data, Error>) -> Void) {
        let session = config.session
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data {
                // Debug: Print response details
                if let httpResponse = response as? HTTPURLResponse {
                    print("Response Status: \(httpResponse.statusCode)")
                    print("Response Headers: \(httpResponse.allHeaderFields)")
                }
                
                // Debug: Print first 500 characters of response
                if let responseString = String(data: data, encoding: .utf8) {
                    let preview = String(responseString.prefix(500))
                    print("Response Preview: \(preview)")
                }
                
                completionHandler(.success(data))
            }
        }
        
        task.resume()
    }
   
    private func prepareRequest<BodyType>(_ endpoint: CosmicEndpointProvider.API, body: BodyType? = nil, id: String? = nil, bucket: String, type: String, read_key: String, write_key: String? = nil, props: String? = nil, limit: String? = nil, skip: String? = nil, title: String? = nil, slug: String? = nil, content: String? = nil, metadata: [String: AnyCodable]? = nil, sort: CosmicEndpointProvider.Sorting? = nil, status: CosmicEndpointProvider.Status? = nil, depth: String? = nil) -> URLRequest where BodyType: Encodable {
        let pathAndParameters = config.endpointProvider.getPath(api: endpoint, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey, props: props, limit: limit, skip: skip, status: status, sort: sort, depth: depth)
        
        // Create URL components based on whether we have a full URL or just a path
        let urlComponents: URLComponents
        if pathAndParameters.0.starts(with: "http") {
            urlComponents = URLComponents(string: pathAndParameters.0)!
        } else {
            let baseURL = URL(string: config.baseURL)!
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
            components.path = pathAndParameters.0
            urlComponents = components
        }
        
        // Add query parameters - only include those with actual values
        var finalComponents = urlComponents
        finalComponents.queryItems = pathAndParameters.1.compactMap { key, value in
            // Skip empty, nil, or whitespace-only values
            guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
                return nil 
            }
            return URLQueryItem(name: key, value: value)
        }
        
        var request = URLRequest(url: finalComponents.url!)
        request.httpMethod = config.endpointProvider.getMethod(api: endpoint)
        
        config.authorizeRequest(&request)
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Debug: Print request details
        print("Request URL: \(request.url?.absoluteString ?? "nil")")
        print("Request Method: \(request.httpMethod ?? "nil")")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        if let body = body {
            if let jsonData = try? JSONEncoder().encode(body) {
                request.httpBody = jsonData
            }
        }
        
        return request
    }

    // Helper method for requests without body
    private func prepareRequest(_ endpoint: CosmicEndpointProvider.API, id: String? = nil, bucket: String, type: String, read_key: String, write_key: String? = nil, props: String? = nil, limit: String? = nil, skip: String? = nil, title: String? = nil, slug: String? = nil, content: String? = nil, metadata: [String: AnyCodable]? = nil, sort: CosmicEndpointProvider.Sorting? = nil, status: CosmicEndpointProvider.Status? = nil, depth: String? = nil) -> URLRequest {
        return prepareRequest(endpoint, body: nil as String?, id: id, bucket: bucket, type: type, read_key: read_key, write_key: write_key, props: props, limit: limit, skip: skip, title: title, slug: slug, content: content, metadata: metadata, sort: sort, status: status, depth: depth)
    }

    private func mimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "svg":
            return "image/svg+xml"
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        default:
            return "application/octet-stream"
        }
    }
}

extension CosmicSDKSwift {
    struct Body: Encodable {
        let type: String?
        let title: String?
        let content: String?
        let metadata: [String: AnyCodable]?
        let status: String?
        let publish_at: String?
        let unpublish_at: String?
    }
    
    public struct SuccessResponse: Decodable {
        public let message: String?
    }
    
    /// Get bucket information including available object types
    public func getBucketInfo(completionHandler: @escaping (Result<BucketResponse, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.getBucket
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        makeRequest(request: request) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BucketResponse.self, from: data)
                    completionHandler(.success(response))
                } catch {
                    completionHandler(.failure(.decodingError(error: error)))
                }
            case .failure(let error):
                completionHandler(.failure(.genericError(error: error)))
            }
        }
    }
    
    /// Test connection to Cosmic API
    public func testConnection(completionHandler: @escaping (Result<String, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.getBucket
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        makeRequest(request: request) { result in
            switch result {
            case .success(let data):
                if let responseString = String(data: data, encoding: .utf8) {
                    completionHandler(.success(responseString))
                } else {
                    completionHandler(.failure(.genericError(error: NSError(domain: "CosmicSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"]))))
                }
            case .failure(let error):
                completionHandler(.failure(.genericError(error: error)))
            }
        }
    }
    
    public func find(type: String, props: String? = nil, limit: Int? = nil, skip: Int? = nil, sort: CosmicSorting? = nil, status: CosmicStatus? = nil, depth: Int? = 1, completionHandler: @escaping (Result<CosmicSDK, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.find
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: type, read_key: config.readKey, props: props, limit: limit?.description, skip: skip?.description, sort: sort, status: status, depth: depth?.description)
        
        makeRequest(request: request) { result in
            switch result {
            case .success(let success):
                do {
                    let res = try JSONDecoder().decode(CosmicSDK.self, from: success)
                    completionHandler(.success(res))
                } catch {
                    completionHandler(.failure(.decodingError(error: error)))
                }
            case .failure(let failure):
                completionHandler(.failure(.genericError(error: failure)))
            }
        }
    }
    

    
    public func findOne(type: String, id: String, props: String? = nil, limit: Int? = nil, status: CosmicStatus? = nil, depth: Int? = 1, completionHandler: @escaping (Result<CosmicSDKSingle, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.findOne
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, props: props, status: status, depth: depth?.description)
                
        makeRequest(request: request) { result in
            switch result {
            case .success(let success):
                do {
                    let res = try JSONDecoder().decode(CosmicSDKSingle.self, from: success)
                    completionHandler(.success(res))
                } catch {
                    completionHandler(.failure(.decodingError(error: error)))
                }
            case .failure(let failure):
                completionHandler(.failure(.genericError(error: failure)))
            }
        }
    }
    

    
    public func insertOne(type: String, props: String? = nil, limit: Int? = nil, title: String, slug: String? = nil, content: String? = nil, metadata: [String: Any]? = nil, status: CosmicStatus? = nil, publish_at: String? = nil, unpublish_at: String? = nil, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.insertOne
        let metadataCodable = metadata.map { $0.mapValues { AnyCodable(value: $0) } }
        
        // If publish_at or unpublish_at is set, force status to draft
        let finalStatus = (publish_at != nil || unpublish_at != nil) ? "draft" : status?.rawValue
        
        let body = Body(type: type.isEmpty ? nil : type, title: title.isEmpty ? nil : title, content: content?.isEmpty == true ? nil : content, metadata: metadataCodable, status: finalStatus, publish_at: publish_at, unpublish_at: unpublish_at)
        let request = prepareRequest(endpoint, body: body, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey, props: props, limit: limit?.description, title: title, slug: slug, content: content, metadata: metadataCodable, status: status)
                
        makeRequest(request: request) { result in
            switch result {
            case .success(let success):
                do {
                    let res = try JSONDecoder().decode(SuccessResponse.self, from: success)
                    completionHandler(.success(res))
                } catch {
                    completionHandler(.failure(.decodingError(error: error)))
                }
            case .failure(let failure):
                completionHandler(.failure(.genericError(error: failure)))
            }
        }
    }
    

    
    public func updateOne(type: String, id: String, props: String? = nil, limit: Int? = nil, title: String? = nil, slug: String? = nil, content: String? = nil, metadata: [String: Any]? = nil, status: CosmicEndpointProvider.Status? = nil, publish_at: String? = nil, unpublish_at: String? = nil, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.updateOne
        let metadataCodable = metadata.map { $0.mapValues { AnyCodable(value: $0) } }
        
        // If publish_at or unpublish_at is set, force status to draft
        let finalStatus = (publish_at != nil || unpublish_at != nil) ? "draft" : status?.rawValue
        
        let body = Body(type: type.isEmpty ? nil : type, title: title, content: content, metadata: metadataCodable, status: finalStatus, publish_at: publish_at, unpublish_at: unpublish_at)
        let request = prepareRequest(endpoint, body: body, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey, props: props, limit: limit?.description, title: title, slug: slug, content: content, metadata: metadataCodable, status: status)

        makeRequest(request: request) { result in
            switch result {
            case .success(let success):
                do {
                    let res = try JSONDecoder().decode(SuccessResponse.self, from: success)
                    completionHandler(.success(res))
                } catch {
                    completionHandler(.failure(.decodingError(error: error)))
                }
            case .failure(let failure):
                completionHandler(.failure(.genericError(error: failure)))
            }
        }
    }
    

    
    public func deleteOne(type: String, id: String, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.deleteOne
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey)
                
        print(request)
        makeRequest(request: request) { result in
            switch result {
            case .success(let success):
                do {
                    let res = try JSONDecoder().decode(SuccessResponse.self, from: success)
                    completionHandler(.success(res))
                } catch {
                    completionHandler(.failure(.decodingError(error: error)))
                }
            case .failure(let failure):
                completionHandler(.failure(.genericError(error: failure)))
            }
        }
    }
}

// MARK: - Media Operations
extension CosmicSDKSwift {
    public func uploadMedia(fileURL: URL, folder: String? = nil, metadata: [String: Any]? = nil) async throws -> CosmicMediaSingleResponse {
        let endpoint = CosmicEndpointProvider.API.uploadMedia(config.bucketSlug)
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = prepareRequest(endpoint, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add file data
        let fileData = try Data(contentsOf: fileURL)
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"media\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType(for: fileURL))\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        
        // Add folder if provided
        if let folder = folder {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(folder)\r\n".data(using: .utf8)!)
        }
        
        // Add metadata if provided
        if let metadata = metadata {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"metadata\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            let metadataData = try JSONSerialization.data(withJSONObject: metadata)
            data.append(metadataData)
            data.append("\r\n".data(using: .utf8)!)
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(CosmicMediaSingleResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        print("Decoding error: \(error)")
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("Response data: \(jsonString)")
                        }
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func getMedia(limit: Int? = nil, skip: Int? = nil, props: String? = nil) async throws -> CosmicMediaResponse {
        let endpoint = CosmicEndpointProvider.API.getMedia
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: "", read_key: config.readKey, props: props, limit: limit?.description)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(CosmicMediaResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    

    
    public func getMediaObject(id: String) async throws -> CosmicMediaSingleResponse {
        let endpoint = CosmicEndpointProvider.API.getMediaObject
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(CosmicMediaSingleResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func deleteMedia(id: String) async throws -> SuccessResponse {
        let endpoint = CosmicEndpointProvider.API.deleteMedia
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
}

// MARK: - Media Operations (Completion Handlers)
extension CosmicSDKSwift {
    public func uploadMedia(fileURL: URL, folder: String? = nil, metadata: [String: Any]? = nil, completionHandler: @escaping (Result<CosmicMediaSingleResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await uploadMedia(fileURL: fileURL, folder: folder, metadata: metadata)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    
    public func getMedia(limit: Int? = nil, skip: Int? = nil, props: String? = nil, completionHandler: @escaping (Result<CosmicMediaResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await getMedia(limit: limit, skip: skip, props: props)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    

    
    public func getMediaObject(id: String, completionHandler: @escaping (Result<CosmicMediaSingleResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await getMediaObject(id: id)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    
    public func deleteMedia(id: String, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await deleteMedia(id: id)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
}

// MARK: - Connection Testing
extension CosmicSDKSwift {
    public func getBucketInfo() async throws -> BucketResponse {
        let endpoint = CosmicEndpointProvider.API.getBucket
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(BucketResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func testConnection() async throws -> String {
        let endpoint = CosmicEndpointProvider.API.getBucket
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    if let responseString = String(data: data, encoding: .utf8) {
                        continuation.resume(returning: responseString)
                    } else {
                        continuation.resume(throwing: CosmicError.genericError(error: NSError(domain: "CosmicSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"])))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
}

// MARK: - Object Operations (Async/Await)
extension CosmicSDKSwift {
    public func find(type: String, props: String? = nil, limit: Int? = nil, skip: Int? = nil, sort: CosmicSorting? = nil, status: CosmicStatus? = nil, depth: Int? = 1) async throws -> CosmicSDK {
        let endpoint = CosmicEndpointProvider.API.find
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: type, read_key: config.readKey, props: props, limit: limit?.description, skip: skip?.description, sort: sort, status: status, depth: depth?.description)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(CosmicSDK.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func findOne(type: String, id: String, props: String? = nil, limit: Int? = nil, status: CosmicStatus? = nil, depth: Int? = 1) async throws -> CosmicSDKSingle {
        let endpoint = CosmicEndpointProvider.API.findOne
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, props: props, status: status, depth: depth?.description)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(CosmicSDKSingle.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func insertOne(type: String, props: String? = nil, limit: Int? = nil, title: String, slug: String? = nil, content: String? = nil, metadata: [String: Any]? = nil, status: CosmicStatus? = nil, publish_at: String? = nil, unpublish_at: String? = nil) async throws -> SuccessResponse {
        let endpoint = CosmicEndpointProvider.API.insertOne
        let metadataCodable = metadata.map { $0.mapValues { AnyCodable(value: $0) } }
        
        // If publish_at or unpublish_at is set, force status to draft
        let finalStatus = (publish_at != nil || unpublish_at != nil) ? "draft" : status?.rawValue
        
        let body = Body(type: type.isEmpty ? nil : type, title: title.isEmpty ? nil : title, content: content?.isEmpty == true ? nil : content, metadata: metadataCodable, status: finalStatus, publish_at: publish_at, unpublish_at: unpublish_at)
        let request = prepareRequest(endpoint, body: body, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey, props: props, limit: limit?.description, title: title, slug: slug, content: content, metadata: metadataCodable, status: status)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func updateOne(type: String, id: String, props: String? = nil, limit: Int? = nil, title: String? = nil, slug: String? = nil, content: String? = nil, metadata: [String: Any]? = nil, status: CosmicStatus? = nil, publish_at: String? = nil, unpublish_at: String? = nil) async throws -> SuccessResponse {
        let endpoint = CosmicEndpointProvider.API.updateOne
        let metadataCodable = metadata.map { $0.mapValues { AnyCodable(value: $0) } }
        
        // If publish_at or unpublish_at is set, force status to draft
        let finalStatus = (publish_at != nil || unpublish_at != nil) ? "draft" : status?.rawValue
        
        let body = Body(type: type.isEmpty ? nil : type, title: title, content: content, metadata: metadataCodable, status: finalStatus, publish_at: publish_at, unpublish_at: unpublish_at)
        let request = prepareRequest(endpoint, body: body, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey, props: props, limit: limit?.description, title: title, slug: slug, content: content, metadata: metadataCodable, status: status)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func deleteOne(type: String, id: String) async throws -> SuccessResponse {
        let endpoint = CosmicEndpointProvider.API.deleteOne
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
}

// MARK: - Object Operations (Additional)
extension CosmicSDKSwift {
    public func getObjectRevisions(id: String) async throws -> ObjectRevisionsResponse {
        let endpoint = CosmicEndpointProvider.API.getObjectRevisions
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(ObjectRevisionsResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func searchObjects(query: String) async throws -> CosmicSDK {
        let endpoint = CosmicEndpointProvider.API.searchObjects
        let searchBody = ["query": query] as [String: String]
        let request = prepareRequest(endpoint, body: searchBody, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(CosmicSDK.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
}

// MARK: - Object Operations (Completion Handlers)
extension CosmicSDKSwift {
    public func getObjectRevisions(id: String, completionHandler: @escaping (Result<ObjectRevisionsResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await getObjectRevisions(id: id)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    
    public func searchObjects(query: String, completionHandler: @escaping (Result<CosmicSDK, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await searchObjects(query: query)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
}

// MARK: - Bucket Operations
extension CosmicSDKSwift {
    public func getBucket() async throws -> BucketResponse {
        let endpoint = CosmicEndpointProvider.API.getBucket
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(BucketResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func updateBucketSettings(settings: BucketSettings) async throws -> SuccessResponse {
        let endpoint = CosmicEndpointProvider.API.updateBucketSettings
        let request = prepareRequest(endpoint, body: settings, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
}

// MARK: - Bucket Operations (Completion Handlers)
extension CosmicSDKSwift {
    public func getBucket(completionHandler: @escaping (Result<BucketResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await getBucket()
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    
    public func updateBucketSettings(settings: BucketSettings, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await updateBucketSettings(settings: settings)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
}

// MARK: - User Operations
extension CosmicSDKSwift {
    public func getUsers() async throws -> UsersResponse {
        let endpoint = CosmicEndpointProvider.API.getUsers
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(UsersResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func getUser(id: String) async throws -> UserSingleResponse {
        let endpoint = CosmicEndpointProvider.API.getUser
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(UserSingleResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func addUser(email: String, role: String) async throws -> UserSingleResponse {
        let endpoint = CosmicEndpointProvider.API.addUser
        let userBody = ["email": email, "role": role] as [String: String]
        let request = prepareRequest(endpoint, body: userBody, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(UserSingleResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func deleteUser(id: String) async throws -> SuccessResponse {
        let endpoint = CosmicEndpointProvider.API.deleteUser
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
}

// MARK: - User Operations (Completion Handlers)
extension CosmicSDKSwift {
    public func getUsers(completionHandler: @escaping (Result<UsersResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await getUsers()
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    
    public func getUser(id: String, completionHandler: @escaping (Result<UserSingleResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await getUser(id: id)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    
    public func addUser(email: String, role: String, completionHandler: @escaping (Result<UserSingleResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await addUser(email: email, role: role)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    
    public func deleteUser(id: String, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await deleteUser(id: id)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
}

// MARK: - Webhook Operations
extension CosmicSDKSwift {
    public func getWebhooks() async throws -> WebhooksResponse {
        let endpoint = CosmicEndpointProvider.API.getWebhooks
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(WebhooksResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func addWebhook(event: String, webhookEndpoint: String) async throws -> SuccessResponse {
        let endpoint = CosmicEndpointProvider.API.addWebhook
        let webhookBody = ["event": event, "endpoint": webhookEndpoint] as [String: String]
        let request = prepareRequest(endpoint, body: webhookBody, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func deleteWebhook(id: String) async throws -> SuccessResponse {
        let endpoint = CosmicEndpointProvider.API.deleteWebhook
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
}

// MARK: - Webhook Operations (Completion Handlers)
extension CosmicSDKSwift {
    public func getWebhooks(completionHandler: @escaping (Result<WebhooksResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await getWebhooks()
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    
    public func addWebhook(event: String, webhookEndpoint: String, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await addWebhook(event: event, webhookEndpoint: webhookEndpoint)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    
    public func deleteWebhook(id: String, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await deleteWebhook(id: id)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
}

// MARK: - AI Operations
extension CosmicSDKSwift {
    public func generateText(prompt: String) async throws -> AITextResponse {
        let endpoint = CosmicEndpointProvider.API.generateText(config.bucketSlug)
        let body = ["prompt": prompt]
        let request = prepareRequest(endpoint, body: body, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    // Print raw response for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw AI response:", jsonString)
                    }
                    do {
                        let response = try JSONDecoder().decode(AITextResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        print("Decoding error:", error)
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("Response data:", jsonString)
                        }
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
    
    public func generateImage(prompt: String, size: String = "1024x1024", quality: String = "standard", style: String = "vivid") async throws -> AIImageResponse {
        let endpoint = CosmicEndpointProvider.API.generateImage(config.bucketSlug)
        let body = [
            "prompt": prompt,
            "size": size,
            "quality": quality,
            "style": style
        ]
        let request = prepareRequest(endpoint, body: body, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            makeRequest(request: request) { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(AIImageResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: CosmicError.decodingError(error: error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: CosmicError.genericError(error: error))
                }
            }
        }
    }
}

// MARK: - AI Operations (Completion Handlers)
extension CosmicSDKSwift {
    public func generateText(prompt: String, completionHandler: @escaping (Result<AITextResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await generateText(prompt: prompt)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
    
    public func generateImage(prompt: String, size: String = "1024x1024", quality: String = "standard", style: String = "vivid", completionHandler: @escaping (Result<AIImageResponse, CosmicError>) -> Void) {
        Task {
            do {
                let result = try await generateImage(prompt: prompt, size: size, quality: quality, style: style)
                completionHandler(.success(result))
            } catch {
                completionHandler(.failure(error as! CosmicError))
            }
        }
    }
}
