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
    
    public enum Status: String {
        case published = "published"
        case draft = "draft"
        case any = "any"
    }

    public enum Sorting: String {
        case created_at = "created_at"
        case reverse_created_at = "-created_at"
        case modified_at = "modified_at"
        case reverse_modified_at = "-modified_at"
        case random = "random"
        case order = "order"
    }
    
    public let source: Source
    public let status: Status
    public let sorting: Sorting
    
    public init(source: CosmicEndpointProvider.Source, status: Status = .published, sorting: Sorting = .order) {
        self.source = source
        self.status = status
        self.sorting = sorting
    }
    
    func getPath(api: API, id: String? = nil, bucket: String, type: String, read_key: String, write_key: String?, props: String? = nil, limit: String? = nil, status: Status? = nil, sort: Sorting? = nil, metadata: [String: AnyCodable]? = nil) -> (String, [String: String?]) {
        
        switch source {
        case .cosmic:
            switch api {
            case .find:
                let queryComponents: [String: String] = ["type": type]
                var queryData: Data? = nil
                if queryComponents.count > 0 {
                    queryData = try? JSONSerialization.data(withJSONObject: queryComponents, options: [])
                }
                let queryString = queryData != nil ? String(data: queryData!, encoding: .utf8) : nil
                var parameters = ["pretty": "true", "query": queryString, "read_key": read_key, "props": props, "limit": limit, "write_key": write_key]
                if let status = status {
                    parameters["status"] = status.rawValue
                }
                if let sort = sort {
                    parameters["sort"] = sort.rawValue
                }
                return ("/v3/buckets/\(bucket)/objects", parameters)
            case .findOne:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
                return ("/v3/buckets/\(bucket)/objects/\(id)", ["read_key": read_key])
            case .updateOne, .deleteOne:
                guard let id = id else { fatalError("Missing ID for \(api) operation") }
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
