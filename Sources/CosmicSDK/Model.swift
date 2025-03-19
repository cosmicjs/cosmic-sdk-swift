//
//  Model.swift
//  
//
//  Created by Karl Koch on 19/09/2023.
//

import Foundation

public struct AnyCodable: Codable {
    public var value: Any

    public init(value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()  // Here we handle null values
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable can't decode the value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if value is NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            // ensure all elements in array are AnyCodable
            try container.encode(array.map {
                guard let val = $0 as? AnyCodable else {
                    throw EncodingError.invalidValue($0, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Invalid array element"))
                }
                return val
            })
        } else if let dictionary = value as? [String: Any] {
            let filteredDictionary = dictionary.compactMapValues { $0 as? AnyCodable }
            try container.encode(filteredDictionary)
        }
    }
}

public struct CosmicSDK: Codable {
    public let objects: [Object]
}

public struct CosmicSDKSingle: Codable {
    public let object: Object
}

public struct Object: Codable {
    public let id: String?
    public let slug: String?
    public let title: String
    public let content: String?
    public let created_at: String?
    public let modified_at: String?
    public let status: String?
    public let published_at: String?
    public let type: String?
    public let metadata: [String: AnyCodable]?
    
    init(id: String? = nil, slug: String? = nil, title: String, content: String? = nil, created_at: String? = nil, modified_at: String? = nil, status: String? = nil, published_at: String? = nil, type: String? = nil, metadata: [String: AnyCodable]? = nil) {
            self.id = id
            self.slug = slug
            self.title = title
            self.content = content
            self.created_at = created_at
            self.modified_at = modified_at
            self.status = status
            self.published_at = published_at
            self.type = type
            self.metadata = metadata
        }
}

struct Command: Codable {
    public let title: String
    public let slug: String?
    public let content: String?
    public let metadata: [String: AnyCodable]?
}

// MARK: - Media Models
public struct CosmicMedia: Codable {
    public let id: String
    public let url: String
    public let imgix_url: String?
    public let original_name: String
    public let size: Int
    public let type: String
    public let created_at: String
    public let modified_at: String
    public let folder: String?
    public let metadata: [String: AnyCodable]?
}

public struct CosmicMediaResponse: Codable {
    public let media: [CosmicMedia]
    public let total: Int
    public let limit: Int?
    public let skip: Int?
}

public struct CosmicMediaSingleResponse: Codable {
    public let media: CosmicMedia
}

// MARK: - Object Revision Models
public struct ObjectRevision: Codable {
    public let id: String
    public let type: String
    public let title: String
    public let content: String?
    public let metadata: [String: AnyCodable]?
    public let status: String
    public let created_at: String
    public let modified_at: String
}

public struct ObjectRevisionsResponse: Codable {
    public let revisions: [ObjectRevision]
    public let total: Int
}

// MARK: - Bucket Models
public struct BucketSettings: Codable {
    public let title: String
    public let description: String?
    public let icon: String?
    public let website: String?
    public let objects_write_key: String?
    public let media_write_key: String?
    public let deploy_hook: String?
    public let env: [String: String]?
}

public struct BucketResponse: Codable {
    public let bucket: BucketSettings
}

// MARK: - User Models
public struct CosmicUser: Codable {
    public let id: String
    public let first_name: String
    public let last_name: String
    public let email: String
    public let role: String
    public let status: String
    public let created_at: String
    public let modified_at: String
}

public struct UsersResponse: Codable {
    public let users: [CosmicUser]
    public let total: Int
}

public struct UserSingleResponse: Codable {
    public let user: CosmicUser
}

// MARK: - Webhook Models
public struct Webhook: Codable {
    public let id: String
    public let event: String
    public let endpoint: String
    public let created_at: String
    public let modified_at: String
}

public struct WebhooksResponse: Codable {
    public let webhooks: [Webhook]
    public let total: Int
}

// MARK: - Error Models
public enum CosmicErrorType: String, Codable {
    case invalidCredentials = "INVALID_CREDENTIALS"
    case notFound = "NOT_FOUND"
    case validationError = "VALIDATION_ERROR"
    case rateLimitExceeded = "RATE_LIMIT_EXCEEDED"
    case serverError = "SERVER_ERROR"
    case unknown = "UNKNOWN_ERROR"
}

public struct CosmicErrorResponse: Codable {
    public let status: Int
    public let type: CosmicErrorType
    public let message: String
    public let details: [String: AnyCodable]?
}
