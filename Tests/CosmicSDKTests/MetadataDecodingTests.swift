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
    
    func testMetadataHelperMethods() throws {
        let json = """
        {
            "title": "Test Object",
            "metadata": [
                {
                    "type": "text",
                    "title": "Name",
                    "key": "name",
                    "value": "John Doe"
                },
                {
                    "type": "text",
                    "title": "Username",
                    "key": "username",
                    "value": "johndoe"
                },
                {
                    "type": "text",
                    "title": "Image URL",
                    "key": "image_url",
                    "value": "https://example.com/image.jpg"
                },
                {
                    "type": "objects",
                    "title": "Shows",
                    "key": "shows",
                    "value": ["show1", "show2", "show3"]
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        // Test metadataValue(for:) method
        let nameValue = object.metadataValue(for: "name")
        XCTAssertNotNil(nameValue)
        XCTAssertEqual(nameValue?.value as? String, "John Doe")
        
        let usernameValue = object.metadataValue(for: "username")
        XCTAssertNotNil(usernameValue)
        XCTAssertEqual(usernameValue?.value as? String, "johndoe")
        
        let imageUrlValue = object.metadataValue(for: "image_url")
        XCTAssertNotNil(imageUrlValue)
        XCTAssertEqual(imageUrlValue?.value as? String, "https://example.com/image.jpg")
        
        let showsValue = object.metadataValue(for: "shows")
        XCTAssertNotNil(showsValue)
        XCTAssertEqual((showsValue?.value as? [String])?.count, 3)
        
        // Test metadataDict property
        let dict = object.metadataDict
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["name"]?.value as? String, "John Doe")
        XCTAssertEqual(dict?["username"]?.value as? String, "johndoe")
        XCTAssertEqual(dict?["image_url"]?.value as? String, "https://example.com/image.jpg")
        XCTAssertEqual((dict?["shows"]?.value as? [String])?.count, 3)
    }
}