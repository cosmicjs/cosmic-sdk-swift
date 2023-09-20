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
            value = Optional<Any>.none as Any
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
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { anyValue in
                guard let value = anyValue as? AnyCodable else {
                    throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath,debugDescription: "Invalid value in array"))
                }
                return value
            })
        } else if value is [String: Any] {
            if let dictionary = value as? [String : AnyCodable] {
                try container.encode(dictionary)
            } else {
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath,debugDescription: "Invalid value in dictionary"))
            }
        } else {
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
