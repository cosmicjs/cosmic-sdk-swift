//
//  File.swift
//  
//
//  Created by Karl Koch on 19/09/2023.
//

import Foundation

public struct CosmicEndpointProvider {
    private let source: Source
    
    public enum Source {
        case cosmic
    }
    
    public init(source: Source) {
        self.source = source
    }
    
    public enum API {
        // Object operations
        case find
        case findOne
        case insertOne
        case updateOne
        case deleteOne
        
        // Media operations
        case uploadMedia(String)
        case getMedia
        case getMediaObject
        case deleteMedia
        
        // Object operations (additional)
        case getObjectRevisions
        case searchObjects
        
        // Bucket operations
        case getBucket
        case updateBucketSettings
        
        // User operations
        case getUsers
        case getUser
        case addUser
        case deleteUser
        
        // Webhook operations
        case getWebhooks
        case addWebhook
        case deleteWebhook
        
        // AI operations
        case generateText(String)
        case generateImage(String)
    }
    
    public enum Status: String {
        case published
        case draft
        case any
    }
    
    public enum Sorting: String {
        case created_at
        case modified_at
        case random
        case order
    }
    
    public func getMethod(api: API) -> String {
        switch source {
        case .cosmic:
            switch api {
            case .find, .findOne, .getMedia, .getMediaObject, .getObjectRevisions, .searchObjects, .getBucket, .getUsers, .getUser, .getWebhooks:
                return "GET"
            case .insertOne, .uploadMedia, .addUser, .addWebhook, .generateText, .generateImage:
                return "POST"
            case .updateOne, .updateBucketSettings:
                return "PATCH"
            case .deleteOne, .deleteMedia, .deleteUser, .deleteWebhook:
                return "DELETE"
            }
        }
    }
    
    public func getPath(api: API, id: String? = nil, bucket: String, type: String, read_key: String, write_key: String?, props: String? = nil, limit: String? = nil, skip: String? = nil, status: Status? = nil, sort: Sorting? = nil, depth: String? = nil, metadata: [String: AnyCodable]? = nil) -> (String, [String: String?]) {
        switch source {
        case .cosmic:
            switch api {
            // Object endpoints
            case .find:
                // Build query parameter for type filtering
                let queryParam = "{\"type\":\"\(type)\"}"
                let defaultProps = "slug,title,metadata,type,"
                let finalProps = props ?? defaultProps
                
                return ("/v3/buckets/\(bucket)/objects", [
                    "query": queryParam,
                    "limit": limit ?? "10",
                    "skip": skip ?? "0",
                    "props": finalProps,
                    "status": status?.rawValue,
                    "sort": sort?.rawValue,
                    "depth": depth,
                    "pretty": "true",
                    "read_key": read_key
                ])
            case .findOne:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                let defaultProps = "slug,title,metadata,type,"
                let finalProps = props ?? defaultProps
                return ("/v3/buckets/\(bucket)/objects/\(id)", [
                    "props": finalProps,
                    "status": status?.rawValue,
                    "depth": depth,
                    "read_key": read_key
                ])
            case .insertOne:
                return ("/v3/buckets/\(bucket)/objects", ["write_key": write_key])
            case .updateOne:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/objects/\(id)", ["write_key": write_key])
            case .deleteOne:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/objects/\(id)", ["write_key": write_key])
                
            // Media endpoints
            case .uploadMedia(let bucket):
                return ("https://workers.cosmicjs.com/v3/buckets/\(bucket)/media", ["write_key": write_key])
            case .getMedia:
                return ("/v3/buckets/\(bucket)/media", ["limit": limit, "props": props])
            case .getMediaObject, .deleteMedia:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/media/\(id)", [:])
                
            // Object operations (additional)
            case .getObjectRevisions:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/objects/\(id)/revisions", [:])
            case .searchObjects:
                return ("/v3/buckets/\(bucket)/objects/search", [:])
                
            // Bucket operations
            case .getBucket:
                return ("/v3/buckets/\(bucket)", [:])
            case .updateBucketSettings:
                return ("/v3/buckets/\(bucket)/settings", ["write_key": write_key])
                
            // User operations
            case .getUsers:
                return ("/v3/buckets/\(bucket)/users", [:])
            case .getUser:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/users/\(id)", [:])
            case .addUser:
                return ("/v3/buckets/\(bucket)/users", ["write_key": write_key])
            case .deleteUser:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/users/\(id)", ["write_key": write_key])
                
            // Webhook operations
            case .getWebhooks:
                return ("/v3/buckets/\(bucket)/webhooks", [:])
            case .addWebhook:
                return ("/v3/buckets/\(bucket)/webhooks", ["write_key": write_key])
            case .deleteWebhook:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/webhooks/\(id)", ["write_key": write_key])
                
            // AI endpoints
            case .generateText(let bucket):
                return ("https://workers.cosmicjs.com/v3/buckets/\(bucket)/ai/text", ["write_key": write_key])
            case .generateImage(let bucket):
                return ("https://workers.cosmicjs.com/v3/buckets/\(bucket)/ai/image", ["write_key": write_key])
            }
        }
    }
}
