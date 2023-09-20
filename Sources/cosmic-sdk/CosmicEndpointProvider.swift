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
    
    func getPath(api: API, id: String?, bucket: String, type: String, read_key: String, write_key: String?, props: String?, limit: String?, title: String?, slug: String?, content: String?, metadata: [String: AnyCodable]?) -> (String, [String: String?]) {
        let write_key = write_key != nil && !write_key!.isEmpty ? "&write_key=\(write_key!)" : ""
        let props = props != nil && !props!.isEmpty ? "&props=\(props!)" : ""
        let limit = limit != nil && !limit!.isEmpty ? "&limit=\(limit!)" : ""
        let id = id != nil && !id!.isEmpty ? id! : ""

        switch source {
        case .cosmic:
            switch api {
            case .find:
                let queryComponents: [String: String] = ["type": type]
                let queryData = try! JSONSerialization.data(withJSONObject: queryComponents, options: [])
                let queryString = String(data: queryData, encoding: .utf8)!
                return ("/v3/buckets/\(bucket)/objects", ["pretty": "true", "query": queryString, "read_key": read_key, "props": props, "limit": limit, "write_key": write_key])
            case .findOne, .updateOne, .deleteOne:
                return ("/v3/buckets/\(bucket)/objects/\(id)", [:])
            case .insertOne:
                return ("/v3/buckets/\(bucket)/objects/", [:])
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
