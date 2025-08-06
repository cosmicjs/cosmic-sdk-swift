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

// MARK: - Metafield Models
public enum MetafieldType: String, Codable {
    case text = "text"
    case textarea = "textarea"
    case htmlTextarea = "html-textarea"
    case markdown = "markdown"
    case selectDropdown = "select-dropdown"
    case object = "object"
    case objects = "objects"
    case file = "file"
    case files = "files"
    case date = "date"
    case json = "json"
    case radioButtons = "radio-buttons"
    case checkBoxes = "check-boxes"
    case `switch` = "switch"
    case color = "color"
    case parent = "parent"
    case repeater = "repeater"
}

public struct MetafieldOption: Codable {
    public let key: String?
    public let value: String
}

public struct RepeaterField: Codable {
    public let title: String
    public let key: String
    public let value: String?
    public let type: MetafieldType
    public let required: Bool?
}

public struct Metafield: Codable {
    public let type: MetafieldType
    public let title: String
    public let key: String
    public var value: AnyCodable?
    public let required: Bool?
    
    // For select-dropdown, radio-buttons, check-boxes
    public let options: [MetafieldOption]?
    
    // For object and objects
    public let object_type: String?
    
    // For parent
    public let children: [Metafield]?
    
    // For repeater
    public let repeater_fields: [RepeaterField]?
    
    private enum CodingKeys: String, CodingKey {
        case type, title, key, value, required, options, object_type, children, repeater_fields
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(MetafieldType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        key = try container.decode(String.self, forKey: .key)
        required = try container.decodeIfPresent(Bool.self, forKey: .required)
        options = try container.decodeIfPresent([MetafieldOption].self, forKey: .options)
        object_type = try container.decodeIfPresent(String.self, forKey: .object_type)
        children = try container.decodeIfPresent([Metafield].self, forKey: .children)
        repeater_fields = try container.decodeIfPresent([RepeaterField].self, forKey: .repeater_fields)
        
        // Handle value based on type
        if type == .objects || type == .files || type == .checkBoxes,
           var valueContainer = try? container.nestedUnkeyedContainer(forKey: .value) {
            var array: [AnyCodable] = []
            while !valueContainer.isAtEnd {
                if let value = try? valueContainer.decode(AnyCodable.self) {
                    array.append(value)
                }
            }
            value = AnyCodable(value: array)
        } else if type == .json,
                  let jsonValue = try? container.decode([String: AnyCodable].self, forKey: .value) {
            value = AnyCodable(value: jsonValue)
        } else if type == .switch,
                  let boolValue = try? container.decode(Bool.self, forKey: .value) {
            value = AnyCodable(value: boolValue)
        } else {
            value = try container.decodeIfPresent(AnyCodable.self, forKey: .value)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(key, forKey: .key)
        try container.encodeIfPresent(required, forKey: .required)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(object_type, forKey: .object_type)
        try container.encodeIfPresent(children, forKey: .children)
        try container.encodeIfPresent(repeater_fields, forKey: .repeater_fields)
        try container.encodeIfPresent(value, forKey: .value)
    }
}

// Object model with structured metadata
public struct Object: Codable {
    public let id: String?
    public let slug: String?
    public let title: String
    public let content: String?
    public let bucket: String?
    public let created_at: String?
    public let created_by: String?
    public let modified_at: String?
    public let modified_by: String?
    public let status: String?
    public let published_at: String?
    public let publish_at: String?
    public let unpublish_at: String?
    public let type: String?
    public let locale: String?
    public let thumbnail: String?
    public let metadata: [Metafield]?
    
    enum CodingKeys: String, CodingKey {
        case id, slug, title, content, bucket, created_at, created_by, modified_at, modified_by, status, published_at, publish_at, unpublish_at, type, locale, thumbnail, metadata, metafields
    }
    
    // Custom decoder to gracefully handle String or numeric publish_at fields
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        bucket = try container.decodeIfPresent(String.self, forKey: .bucket)
        created_at = try container.decodeIfPresent(String.self, forKey: .created_at)
        created_by = try container.decodeIfPresent(String.self, forKey: .created_by)
        modified_at = try container.decodeIfPresent(String.self, forKey: .modified_at)
        modified_by = try container.decodeIfPresent(String.self, forKey: .modified_by)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        published_at = try Object.decodeStringOrNumber(from: container, forKey: .published_at)
        publish_at = try Object.decodeStringOrNumber(from: container, forKey: .publish_at)
        unpublish_at = try Object.decodeStringOrNumber(from: container, forKey: .unpublish_at)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        locale = try container.decodeIfPresent(String.self, forKey: .locale)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        
        // Try to decode from 'metadata' first, then fall back to 'metafields' for backward compatibility
        if let metadataValue = try container.decodeIfPresent([Metafield].self, forKey: .metadata) {
            metadata = metadataValue
        } else {
            metadata = try container.decodeIfPresent([Metafield].self, forKey: .metafields)
        }
    }
    
    // We rarely encode Object back to JSON in the SDK. Implement minimal encoder.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(bucket, forKey: .bucket)
        try container.encodeIfPresent(created_at, forKey: .created_at)
        try container.encodeIfPresent(created_by, forKey: .created_by)
        try container.encodeIfPresent(modified_at, forKey: .modified_at)
        try container.encodeIfPresent(modified_by, forKey: .modified_by)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(published_at, forKey: .published_at)
        try container.encodeIfPresent(publish_at, forKey: .publish_at)
        try container.encodeIfPresent(unpublish_at, forKey: .unpublish_at)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(locale, forKey: .locale)
        try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
    
    // Helper to decode String or numeric value
    private static func decodeStringOrNumber(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> String? {
        if let stringVal = try? container.decodeIfPresent(String.self, forKey: key) {
            return stringVal
        }
        if let intVal = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(intVal)
        }
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: key) {
            return String(doubleVal)
        }
        return nil
    }
}

struct Command: Codable {
    public let title: String
    public let slug: String?
    public let content: String?
    public let metadata: [String: AnyCodable]?
}

// MARK: - Object Extensions
extension Object {
    /// Access metafield by key for easier usage
    public func metafieldValue(for key: String) -> AnyCodable? {
        return metafields?.first(where: { $0.key == key })?.value
    }
    
    /// Get all metafields as a dictionary for convenience
    public var metafieldsDict: [String: AnyCodable]? {
        guard let metafields = metafields else { return nil }
        var dict: [String: AnyCodable] = [:]
        for field in metafields {
            if let value = field.value {
                dict[field.key] = value
            }
        }
        return dict.isEmpty ? nil : dict
    }
}

// MARK: - Media Models
public struct CosmicMedia: Codable {
    public let id: String
    public let name: String
    public let original_name: String
    public let size: Int
    public let type: String
    public let bucket: String
    public let created_at: String
    public let created_by: String?
    public let folder: String?
    public let status: String?
    public let alt_text: String?
    public let width: Int?
    public let height: Int?
    public let url: String
    public let imgix_url: String?
    public let metadata: [String: AnyCodable]?
}

public struct CosmicMediaResponse: Codable {
    public let media: [CosmicMedia]
    public let total: Int
    public let limit: Int?
    public let skip: Int?
}

public struct CosmicMediaSingleResponse: Codable {
    public let message: String?
    public let media: CosmicMedia?
    
    private enum CodingKeys: String, CodingKey {
        case message, media
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        media = try container.decodeIfPresent(CosmicMedia.self, forKey: .media)
    }
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

// MARK: - AI Response Models
public struct AITextUsage: Codable {
    public let input_tokens: Int
    public let output_tokens: Int
}

public struct AITextResponse: Codable {
    public let text: String
    public let usage: AITextUsage
}

public struct AIImageResponse: Codable {
    public let url: String
}
