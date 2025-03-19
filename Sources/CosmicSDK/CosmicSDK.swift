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
                    request.setValue("Bearer \(writeKey)", forHTTPHeaderField: "Authorization")
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
                completionHandler(.success(data))
            }
        }
        
        task.resume()
    }
   
    private func prepareRequest<BodyType>(_ endpoint: CosmicEndpointProvider.API, body: BodyType? = nil, id: String? = nil, bucket: String, type: String, read_key: String, write_key: String? = nil, props: String? = nil, limit: String? = nil, title: String? = nil, slug: String? = nil, content: String? = nil, metadata: [String: AnyCodable]? = nil, sort: CosmicEndpointProvider.Sorting? = nil, status: CosmicEndpointProvider.Status? = nil) -> URLRequest where BodyType: Encodable {
        let requestURL = URL(string: config.baseURL)!
        var urlComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)!

        let pathAndParameters = config.endpointProvider.getPath(api: endpoint, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey, props: props, limit: limit, status: status, sort: sort)

        // Set the path
        urlComponents.path = pathAndParameters.0

        // Create the URLQueryItems
        urlComponents.queryItems = pathAndParameters.1.compactMap { URLQueryItem(name: $0.key, value: $0.value) }

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = config.endpointProvider.getMethod(api: endpoint)
        
        config.authorizeRequest(&request)
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            if let jsonData = try? JSONEncoder().encode(body) {
                request.httpBody = jsonData
            }
        }
        
        return request
    }

    // Helper method for requests without body
    private func prepareRequest(_ endpoint: CosmicEndpointProvider.API, id: String? = nil, bucket: String, type: String, read_key: String, write_key: String? = nil, props: String? = nil, limit: String? = nil, title: String? = nil, slug: String? = nil, content: String? = nil, metadata: [String: AnyCodable]? = nil, sort: CosmicEndpointProvider.Sorting? = nil, status: CosmicEndpointProvider.Status? = nil) -> URLRequest {
        return prepareRequest(endpoint, body: nil as String?, id: id, bucket: bucket, type: type, read_key: read_key, write_key: write_key, props: props, limit: limit, title: title, slug: slug, content: content, metadata: metadata, sort: sort, status: status)
    }
}

extension CosmicSDKSwift {
    struct Body: Encodable {
        let type: String?
        let title: String?
        let content: String?
        let metadata: [String: AnyCodable]?
        let status: String?
    }
    
    public struct SuccessResponse: Decodable {
        public let message: String?
    }
    
    public func find(type: String, props: String? = nil, limit: String? = nil, sort: CosmicEndpointProvider.Sorting? = nil, status: CosmicEndpointProvider.Status? = nil, completionHandler: @escaping (Result<CosmicSDK, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.find
        let request = prepareRequest(endpoint, bucket: config.bucketSlug, type: type, read_key: config.readKey, limit: limit, sort: sort, status: status)
        
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
    
    public func findOne(type: String, id: String, props: String? = nil, limit: String? = nil, status: CosmicEndpointProvider.Status? = nil, completionHandler: @escaping (Result<CosmicSDKSingle, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.findOne
        let request = prepareRequest(endpoint, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, status: status)
                
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
    
    public func insertOne(type: String, props: String? = nil, limit: String? = nil, title: String, slug: String? = nil, content: String? = nil, metadata: [String: Any]? = nil, status: CosmicEndpointProvider.Status? = nil, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.insertOne
        let metadataCodable = metadata.map { $0.mapValues { AnyCodable(value: $0) } }
        let body = Body(type: type.isEmpty ? nil : type, title: title.isEmpty ? nil : title, content: content?.isEmpty == true ? nil : content, metadata: metadataCodable, status: status?.rawValue)
        let request = prepareRequest(endpoint, body: body, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey, props: props, limit: limit, title: title, slug: slug, content: content, metadata: metadataCodable, status: status)
                
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
    
    public func updateOne(type: String, id: String, props: String? = nil, limit: String? = nil, title: String? = nil, slug: String? = nil, content: String? = nil, metadata: [String: Any]? = nil, status: CosmicEndpointProvider.Status? = nil, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.updateOne
        let metadataCodable = metadata.map { $0.mapValues { AnyCodable(value: $0) } }
        let body = Body(type: type.isEmpty ? nil : type, title: title, content: content, metadata: metadataCodable, status: status?.rawValue)
        let request = prepareRequest(endpoint, body: body, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey, props: props, limit: limit, title: title, slug: slug, content: content, metadata: metadataCodable, status: status)

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
        data.append("Content-Disposition: form-data; name=\"media\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        
        // Create media object matching Node SDK structure
        let mediaObject: [String: Any] = [
            "originalname": fileURL.lastPathComponent,
            "buffer": fileData.base64EncodedString()
        ]
        
        let mediaData = try JSONSerialization.data(withJSONObject: mediaObject)
        data.append(mediaData)
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
        var request = prepareRequest(endpoint, body: searchBody, bucket: config.bucketSlug, type: "", read_key: config.readKey)
        
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
        var request = prepareRequest(endpoint, body: settings, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
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
        var request = prepareRequest(endpoint, body: userBody, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
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
        var request = prepareRequest(endpoint, body: webhookBody, bucket: config.bucketSlug, type: "", read_key: config.readKey, write_key: config.writeKey)
        
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
