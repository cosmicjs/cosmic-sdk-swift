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
