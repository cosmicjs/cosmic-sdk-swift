//
//  File.swift
//  
//
//  Created by Karl Koch on 19/09/2023.
//

import Foundation

public struct CosmicEndpointProvider {
    public enum API {
        case find
        case findOne
        case insertOne
        case updateOne
        case deleteOne
    }
    
    public enum Source {
        case cosmic
    }
    
    public let source: Source
    
    public init(source: CosmicEndpointProvider.Source) {
        self.source = source
    }
    
    func getPath(api: API, id: String?, bucket: String, type: String, read_key: String, write_key: String?, props: String?, limit: String?, title: String?, slug: String?, content: String?, metadata: [String: AnyCodable]?) -> String {
        let write_key = "&write_key=\(String(describing: write_key))"
        let props = "&props=\(String(describing: props))"
        let limit = "&limit=\(String(describing: limit))"
        if let id = id {
            return id
        } else {
            print("Error: Please provide an object id")
        }
        
        switch source {
        case .cosmic:
            switch api {
            case .find:
                return "/v3/buckets/\(bucket)/objects?pretty=true&query=%7B%22type%22%3A%22\(type)%22%7D&read_key=\(read_key)\(write_key)\(props)\(limit)"
            case .findOne:
                return "/v3/buckets/\(bucket)/objects/\(id!)"
            case .insertOne:
                return "/v3/buckets/\(bucket)/objects/"
            case .updateOne:
                return "/v3/buckets/\(bucket)/objects/\(id!)"
            case .deleteOne:
                return "/v3/buckets/\(bucket)/objects/\(id!)"
            }
        }
    }
    
    func getMethod(api: API) -> String {
        switch source {
        case .cosmic:
            switch api {
            case .find, .findOne:
                return "GET"
            case .insertOne:
                return "POST"
            case .updateOne:
                return "PATCH"
            case .deleteOne:
                return "DELETE"
            }
        }
    }
}
