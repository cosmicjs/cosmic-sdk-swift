//
//  MetadataDictionaryTests.swift
//  
//
//  Created to test dictionary-based metadata format
//

import XCTest
@testable import CosmicSDK

final class MetadataDictionaryTests: XCTestCase {
    
    func testDecodingDictionaryMetadata() throws {
        let json = """
        {
            "title": "Test Object",
            "metadata": {
                "name": "John Doe",
                "username": "johndoe",
                "age": 25,
                "active": true,
                "tags": ["swift", "ios", "development"],
                "profile": {
                    "bio": "Developer",
                    "location": "San Francisco"
                }
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        XCTAssertEqual(object.title, "Test Object")
        XCTAssertNotNil(object.metadata)
        
        // Test accessing values via value(for:) method
        XCTAssertEqual(object.metafieldValue(for: "name")?.value as? String, "John Doe")
        XCTAssertEqual(object.metafieldValue(for: "username")?.value as? String, "johndoe")
        XCTAssertEqual(object.metafieldValue(for: "age")?.value as? Int, 25)
        XCTAssertEqual(object.metafieldValue(for: "active")?.value as? Bool, true)
        
        // Test accessing array values
        if let tags = object.metafieldValue(for: "tags")?.value as? [Any] {
            XCTAssertEqual(tags.count, 3)
            XCTAssertEqual(tags[0] as? String, "swift")
        }
        
        // Test accessing nested object values
        if let profile = object.metafieldValue(for: "profile")?.value as? [String: Any] {
            XCTAssertEqual(profile["bio"] as? String, "Developer")
            XCTAssertEqual(profile["location"] as? String, "San Francisco")
        }
    }
    
    func testDynamicMemberLookup() throws {
        let json = """
        {
            "title": "Test Object",
            "metadata": {
                "name": "John Doe",
                "email": "john@example.com",
                "is_premium": true
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        // Test dynamic member lookup on metadata - direct comparison!
        XCTAssertEqual(object.metadata?.name, "John Doe")
        XCTAssertEqual(object.metadata?.email, "john@example.com")
        XCTAssertEqual(object.metadata?.is_premium, true)
        
        // Or if you need to store in variables
        let name = object.metadata?.name.string
        let email = object.metadata?.email.string
        let isPremium = object.metadata?.is_premium.bool
        
        XCTAssertEqual(name, "John Doe")
        XCTAssertEqual(email, "john@example.com")
        XCTAssertEqual(isPremium, true)
        
        // Test accessing non-existent property
        XCTAssertNil(object.metadata?.non_existent.string)
        XCTAssertFalse(object.metadata?.non_existent.exists ?? true)
    }
    
    func testBackwardCompatibilityWithArrayFormat() throws {
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
                    "title": "Email",
                    "key": "email",
                    "value": "john@example.com"
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        // Should still work with array format
        XCTAssertEqual(object.metafieldValue(for: "name")?.value as? String, "John Doe")
        XCTAssertEqual(object.metafieldValue(for: "email")?.value as? String, "john@example.com")
        
        // Test accessing as array
        let fields = object.metafields
        XCTAssertNotNil(fields)
        XCTAssertEqual(fields?.count, 2)
        
        // Test accessing as dictionary
        let dict = object.metafieldsDict
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?.count, 2)
    }
    
    func testMixedContentTypes() throws {
        let json = """
        {
            "title": "Event Object",
            "metadata": {
                "event_name": "CosmicCon 2024",
                "start_date": "2024-06-15",
                "attendee_count": 500,
                "is_virtual": false,
                "venue": {
                    "name": "Convention Center",
                    "address": "123 Main St"
                },
                "speakers": ["Alice", "Bob", "Charlie"],
                "ticket_prices": {
                    "early_bird": 99.99,
                    "regular": 149.99,
                    "vip": 299.99
                }
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        // Test various types - clean and type-safe!
        XCTAssertEqual(object.metadata?.event_name.string, "CosmicCon 2024")
        XCTAssertEqual(object.metadata?.attendee_count.int, 500)
        XCTAssertEqual(object.metadata?.is_virtual.bool, false)
        
        // Test nested objects and arrays
        if let speakers = object.metadata?.speakers.array(of: String.self) {
            XCTAssertEqual(speakers.count, 3)
            XCTAssertEqual(speakers[0], "Alice")
        }
        
        if let prices = object.metadata?.ticket_prices.dictionary(keyType: String.self, valueType: Any.self) {
            XCTAssertEqual(prices["early_bird"] as? Double, 99.99)
        }
    }
    
    func testEncodingDictionaryMetadata() throws {
        let json = """
        {
            "title": "Test Object",
            "metadata": {
                "name": "John Doe",
                "active": true
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let object = try JSONDecoder().decode(Object.self, from: data)
        
        // Re-encode and verify structure is preserved
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let encodedData = try encoder.encode(object)
        let encodedString = String(data: encodedData, encoding: .utf8)!
        
        // Should contain metadata as a dictionary
        XCTAssertTrue(encodedString.contains("\"metadata\" : {"))
        XCTAssertTrue(encodedString.contains("\"name\" : \"John Doe\""))
        XCTAssertTrue(encodedString.contains("\"active\" : true"))
    }
}
