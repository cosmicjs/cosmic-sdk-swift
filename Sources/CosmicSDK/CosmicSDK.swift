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
   
    private func prepareRequest<BodyType: Encodable>(_ endpoint: CosmicEndpointProvider.API, body: BodyType? = nil, id: String? = nil, bucket: String, type: String, read_key: String, write_key: String? = nil, props: String? = nil, limit: String? = nil, title: String? = nil, slug: String? = nil, content: String? = nil, metadata: [String: AnyCodable]? = nil, sort: CosmicEndpointProvider.Sorting? = nil, status: CosmicEndpointProvider.Status? = nil) -> URLRequest {
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
        
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        if let body = body {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(body) {
                request.httpBody = encoded
            }
        } else {
            // Convert the optional parameters to a dictionary
            var parameters = [String: Any]()
            if let title = title {
                parameters["title"] = title
            }
            if let slug = slug {
                parameters["slug"] = slug
            }
            if let content = content {
                parameters["content"] = content
            }
            if let metadata = metadata {
                parameters["metadata"] = metadata
            }
            if !parameters.isEmpty {
                if let encodedParameters = try? JSONSerialization.data(withJSONObject: parameters, options: []) {
                    request.httpBody = encodedParameters
                }
            }
        }
        return request
    }
}

extension CosmicSDKSwift {
    struct Body: Encodable {
        let type: String?
        let title: String?
        let content: String?
        let metadata: [String: AnyCodable]?
    }
    
    public struct SuccessResponse: Decodable {
        public let message: String
    }
    
    public func find(type: String, props: String? = nil, limit: String? = nil, sort: CosmicEndpointProvider.Sorting? = nil, status: CosmicEndpointProvider.Status? = nil, completionHandler: @escaping (Result<CosmicSDK, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.find
        let request = prepareRequest(endpoint, body: nil as AnyCodable?, bucket: config.bucketSlug, type: type, read_key: config.readKey, limit: limit, sort: sort, status: status)
        
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
    
    public func findOne(type: String, id: String, props: String? = nil, limit: String? = nil, status: CosmicEndpointProvider.Status? = nil, completionHandler: @escaping (Result<CosmicSDK, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.findOne
        let request = prepareRequest(endpoint, body: nil as AnyCodable?, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, status: status)
                
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
    
    public func insertOne(type: String, id: String, props: String, limit: String? = nil, title: String, slug: String? = nil, content: String? = nil, metadata: [String: AnyCodable]? = nil, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.insertOne
        let body = Body(type: type.isEmpty ? nil : type, title: title.isEmpty ? nil : title, content: content?.isEmpty == true ? nil : content, metadata: metadata?.isEmpty == true ? nil : metadata)
        let request = prepareRequest(endpoint, body: body, id: nil, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey, props: props, limit: limit, title: title, slug: slug, content: content, metadata: metadata)
                
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
    
    public func updateOne(type: String, id: String, props: String? = nil, limit: String? = nil, title: String, slug: String? = nil, content: String? = nil, metadata: [String: AnyCodable]? = nil, status: CosmicEndpointProvider.Status? = nil, completionHandler: @escaping (Result<CosmicSDK, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.updateOne
        let body = Body(type: type.isEmpty ? nil : type, title: title.isEmpty ? nil : title, content: content?.isEmpty == true ? nil : content, metadata: metadata?.isEmpty == true ? nil : metadata)
        let request = prepareRequest(endpoint, body: body, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey, props: props, limit: limit, title: title, slug: slug, content: content, metadata: metadata, status: status)

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
    
    public func deleteOne(type: String, id: String, completionHandler: @escaping (Result<SuccessResponse, CosmicError>) -> Void) {
        let endpoint = CosmicEndpointProvider.API.deleteOne
        let request = prepareRequest(endpoint, body: nil as AnyCodable?, id: id, bucket: config.bucketSlug, type: type, read_key: config.readKey, write_key: config.writeKey)
                
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
