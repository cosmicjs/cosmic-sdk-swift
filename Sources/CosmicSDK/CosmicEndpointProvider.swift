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
        case getMedia
        case uploadMedia(String)
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
        
        var requiresWriteKey: Bool {
            switch self {
            case .insertOne, .updateOne, .deleteOne, .uploadMedia, .deleteMedia,
                 .updateBucketSettings, .addUser, .deleteUser, .addWebhook, .deleteWebhook,
                 .generateText, .generateImage:
                return true
            default:
                return false
            }
        }
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
            case .insertOne, .uploadMedia, .addUser, .addWebhook, .generateText, .generateImage:
                return "POST"
            case .updateOne, .updateBucketSettings:
                return "PATCH"
            case .deleteOne, .deleteMedia, .deleteUser, .deleteWebhook:
                return "DELETE"
            }
        }
    }
    
    public func getPath(api: API, id: String? = nil, bucket: String, type: String, read_key: String, write_key: String? = nil, props: String? = nil, limit: String? = nil, status: Status? = nil, sort: Sorting? = nil) -> (String, [String: String]) {
        var parameters: [String: String] = [:]
        
        if let props = props {
            parameters["props"] = props
        }
        if let limit = limit {
            parameters["limit"] = limit
        }
        if let status = status {
            parameters["status"] = status.rawValue
        }
        if let sort = sort {
            parameters["sort"] = sort.rawValue
        }
        if let write_key = write_key, api.requiresWriteKey {
            parameters["write_key"] = write_key
        }
        
        switch api {
        case .find:
            parameters["type"] = type
            parameters["read_key"] = read_key
            return ("/v3/buckets/\(bucket)/objects", parameters)
        case .findOne:
            parameters["read_key"] = read_key
            return ("/v3/buckets/\(bucket)/objects/\(id ?? "")", parameters)
        case .insertOne:
            return ("/v3/buckets/\(bucket)/objects", parameters)
        case .updateOne:
            return ("/v3/buckets/\(bucket)/objects/\(id ?? "")", parameters)
        case .deleteOne:
            return ("/v3/buckets/\(bucket)/objects/\(id ?? "")", parameters)
        case .getMedia:
            parameters["read_key"] = read_key
            return ("/v3/buckets/\(bucket)/media", parameters)
        case .uploadMedia(let bucket):
            return ("https://workers.cosmicjs.com/v3/buckets/\(bucket)/media/insert-one", parameters)
        case .getMediaObject:
            parameters["read_key"] = read_key
            return ("/v3/buckets/\(bucket)/media/\(id ?? "")", parameters)
        case .deleteMedia:
            return ("/v3/buckets/\(bucket)/media/\(id ?? "")", parameters)
        case .getObjectRevisions:
            parameters["read_key"] = read_key
            return ("/v3/buckets/\(bucket)/objects/\(id ?? "")/revisions", parameters)
        case .searchObjects:
            parameters["read_key"] = read_key
            return ("/v3/buckets/\(bucket)/objects/search", parameters)
        case .getBucket:
            parameters["read_key"] = read_key
            return ("/v3/buckets/\(bucket)", parameters)
        case .updateBucketSettings:
            return ("/v3/buckets/\(bucket)/settings", parameters)
        case .getUsers:
            parameters["read_key"] = read_key
            return ("/v3/buckets/\(bucket)/users", parameters)
        case .getUser:
            parameters["read_key"] = read_key
            return ("/v3/buckets/\(bucket)/users/\(id ?? "")", parameters)
        case .addUser:
            return ("/v3/buckets/\(bucket)/users", parameters)
        case .deleteUser:
            return ("/v3/buckets/\(bucket)/users/\(id ?? "")", parameters)
        case .getWebhooks:
            parameters["read_key"] = read_key
            return ("/v3/buckets/\(bucket)/webhooks", parameters)
        case .addWebhook:
            return ("/v3/buckets/\(bucket)/webhooks", parameters)
        case .deleteWebhook:
            return ("/v3/buckets/\(bucket)/webhooks/\(id ?? "")", parameters)
        case .generateText(let bucket):
            return ("https://workers.cosmicjs.com/v3/buckets/\(bucket)/ai/text", parameters)
        case .generateImage(let bucket):
            return ("https://workers.cosmicjs.com/v3/buckets/\(bucket)/ai/image", parameters)
        }
    }
}
