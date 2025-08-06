//
//  MetadataDecodingTests.swift
//
//
//  Created to test metadata/metafields backward compatibility
//

import XCTest
@testable import CosmicSDK

final class MetadataDecodingTests: XCTestCase {
    
    func testDecodingWithMetadataProperty() throws {
        let json = """
        {
            "title": "Test Object",
            "metadata": [
                {
                    "type": "text",
                    "title": "Test Field",
                    "key": "test_field",
                    "value": "Test Value"
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        XCTAssertEqual(object.title, "Test Object")
        XCTAssertNotNil(object.metadata)
        XCTAssertEqual(object.metadata?.count, 1)
        XCTAssertEqual(object.metadata?.first?.key, "test_field")
    }
    
    func testDecodingWithMetafieldsProperty() throws {
        let json = """
        {
            "title": "Test Object",
            "metafields": [
                {
                    "type": "text",
                    "title": "Test Field",
                    "key": "test_field",
                    "value": "Test Value"
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        XCTAssertEqual(object.title, "Test Object")
        XCTAssertNotNil(object.metadata)
        XCTAssertEqual(object.metadata?.count, 1)
        XCTAssertEqual(object.metadata?.first?.key, "test_field")
    }
    
    func testEncodingUsesMetadataProperty() throws {
        // First decode an object, then re-encode it to verify it uses "metadata"
        let json = """
        {
            "title": "Test Object",
            "metadata": [
                {
                    "type": "text",
                    "title": "Test Field",
                    "key": "test_field",
                    "value": "Test Value"
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedData = try encoder.encode(object)
        let encodedJson = String(data: encodedData, encoding: .utf8)!
        
        XCTAssertTrue(encodedJson.contains("\"metadata\""))
        XCTAssertFalse(encodedJson.contains("\"metafields\""))
    }
}