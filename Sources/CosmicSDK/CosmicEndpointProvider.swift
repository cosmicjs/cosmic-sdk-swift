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
    }
    
    public enum Status: String {
        case published
        case draft
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
            case .insertOne, .uploadMedia, .addUser, .addWebhook:
                return "POST"
            case .updateOne, .updateBucketSettings:
                return "PATCH"
            case .deleteOne, .deleteMedia, .deleteUser, .deleteWebhook:
                return "DELETE"
            }
        }
    }
    
    public func getPath(api: API, id: String? = nil, bucket: String, type: String, read_key: String, write_key: String?, props: String? = nil, limit: String? = nil, status: Status? = nil, sort: Sorting? = nil, metadata: [String: AnyCodable]? = nil) -> (String, [String: String?]) {
        switch source {
        case .cosmic:
            switch api {
            // Object endpoints
            case .find:
                return ("/v3/buckets/\(bucket)/objects", ["read_key": read_key, "type": type, "limit": limit, "props": props, "status": status?.rawValue, "sort": sort?.rawValue])
            case .findOne:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/objects/\(id)", ["read_key": read_key, "props": props, "status": status?.rawValue])
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
                return ("/v3/buckets/\(bucket)/media", ["read_key": read_key, "limit": limit, "props": props])
            case .getMediaObject, .deleteMedia:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/media/\(id)", ["read_key": read_key])
                
            // Object operations (additional)
            case .getObjectRevisions:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/objects/\(id)/revisions", ["read_key": read_key])
            case .searchObjects:
                return ("/v3/buckets/\(bucket)/objects/search", ["read_key": read_key])
                
            // Bucket operations
            case .getBucket:
                return ("/v3/buckets/\(bucket)", ["read_key": read_key])
            case .updateBucketSettings:
                return ("/v3/buckets/\(bucket)/settings", ["write_key": write_key])
                
            // User operations
            case .getUsers:
                return ("/v3/buckets/\(bucket)/users", ["read_key": read_key])
            case .getUser:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/users/\(id)", ["read_key": read_key])
            case .addUser:
                return ("/v3/buckets/\(bucket)/users", ["write_key": write_key])
            case .deleteUser:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/users/\(id)", ["write_key": write_key])
                
            // Webhook operations
            case .getWebhooks:
                return ("/v3/buckets/\(bucket)/webhooks", ["read_key": read_key])
            case .addWebhook:
                return ("/v3/buckets/\(bucket)/webhooks", ["write_key": write_key])
            case .deleteWebhook:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/webhooks/\(id)", ["write_key": write_key])
            }
        }
    }
}
