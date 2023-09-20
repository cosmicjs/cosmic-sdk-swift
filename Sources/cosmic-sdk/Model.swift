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
            value = NSNull()
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
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let string as String:
            try container.encode(string)
        case let values as [Any]:
            try container.encode(values.map { if let value = $0 as? AnyCodable { return value }
                        throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath,debugDescription: "Invalid value in array"))})
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { if let value = $0 as? AnyCodable { return value }
                        throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath,debugDescription: "Invalid value in dictionary"))})
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath,debugDescription: "AnyCodable can't encode this value"))
        }
    }
}

public protocol Payload: Codable { }

public struct CosmicSDK<T: Payload>: Codable {
    public let objects: [Object]
}

public struct Object: Payload {
    public let id: String?
    public let title: String
    public let slug: String?
    public let content: String?
    public let metadata: [String: AnyCodable]?
}

struct Command: Encodable {
    public let title: String
    public let slug: String?
    public let content: String?
    public let metadata: [String: AnyCodable]?
}
