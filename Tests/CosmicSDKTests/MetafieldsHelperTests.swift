//
//  MetafieldsHelperTests.swift
//
//
//  Created to test metafields helper methods
//

import XCTest
@testable import CosmicSDK

final class MetafieldsHelperTests: XCTestCase {
    
    func testMetafieldValueHelper() throws {
        let json = """
        {
            "title": "Test Object",
            "metafields": [
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
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        // Test metafieldValue(for:) method
        let nameValue = object.metafieldValue(for: "name")
        XCTAssertNotNil(nameValue)
        XCTAssertEqual(nameValue?.value as? String, "John Doe")
        
        let usernameValue = object.metafieldValue(for: "username")
        XCTAssertNotNil(usernameValue)
        XCTAssertEqual(usernameValue?.value as? String, "johndoe")
        
        let imageUrlValue = object.metafieldValue(for: "image_url")
        XCTAssertNotNil(imageUrlValue)
        XCTAssertEqual(imageUrlValue?.value as? String, "https://example.com/image.jpg")
        
        // Test non-existent key
        let nonExistent = object.metafieldValue(for: "non_existent")
        XCTAssertNil(nonExistent)
    }
    
    func testMetafieldsDictHelper() throws {
        let json = """
        {
            "title": "Test Object",
            "metafields": [
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
        
        // Test metafieldsDict property
        let dict = object.metafieldsDict
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?.count, 3)
        XCTAssertEqual(dict?["name"]?.value as? String, "John Doe")
        XCTAssertEqual(dict?["username"]?.value as? String, "johndoe")
        XCTAssertEqual((dict?["shows"]?.value as? [String])?.count, 3)
    }
    
    func testEmptyMetafields() throws {
        let json = """
        {
            "title": "Test Object",
            "metafields": []
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        let value = object.metafieldValue(for: "any_key")
        XCTAssertNil(value)
        
        let dict = object.metafieldsDict
        XCTAssertNil(dict)
    }
    
    func testNilMetafields() throws {
        let json = """
        {
            "title": "Test Object"
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        let value = object.metafieldValue(for: "any_key")
        XCTAssertNil(value)
        
        let dict = object.metafieldsDict
        XCTAssertNil(dict)
    }
}
