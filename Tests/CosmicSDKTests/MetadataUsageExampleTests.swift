//
//  MetadataUsageExampleTests.swift
//  
//
//  Created to demonstrate the cleaner metadata API usage
//

import XCTest
@testable import CosmicSDK

final class MetadataUsageExampleTests: XCTestCase {
    
    func testCleanMetadataAccess() throws {
        // Example of a typical Cosmic CMS response with dictionary metadata
        let json = """
        {
            "title": "John Doe",
            "type": "users",
            "metadata": {
                "name": "John Doe",
                "email": "john@example.com",
                "age": 30,
                "is_premium": true,
                "bio": "Software developer from San Francisco",
                "skills": ["Swift", "TypeScript", "Python"],
                "social": {
                    "twitter": "@johndoe",
                    "github": "johndoe"
                }
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let user = try JSONDecoder().decode(Object.self, from: data)
        
        // Clean, direct access to metadata values - no casting needed!
        let name = user.metadata?.name.string
        let email = user.metadata?.email.string
        let age = user.metadata?.age.int
        let isPremium = user.metadata?.is_premium.bool
        let bio = user.metadata?.bio.string
        
        XCTAssertEqual(name, "John Doe")
        XCTAssertEqual(email, "john@example.com")
        XCTAssertEqual(age, 30)
        XCTAssertEqual(isPremium, true)
        XCTAssertEqual(bio, "Software developer from San Francisco")
        
        // Accessing arrays - type-safe!
        if let skills = user.metadata?.skills.array(of: String.self) {
            XCTAssertEqual(skills.count, 3)
            XCTAssertTrue(skills.contains("Swift"))
        }
        
        // Accessing nested objects - clean API
        if let social = user.metadata?.social.dictionary(keyType: String.self, valueType: Any.self) {
            XCTAssertEqual(social["twitter"] as? String, "@johndoe")
            XCTAssertEqual(social["github"] as? String, "johndoe")
        }
    }
    
    func testRealWorldExample() throws {
        // Example: Event object from Cosmic CMS
        let json = """
        {
            "title": "Swift Conference 2024",
            "type": "events",
            "metadata": {
                "event_name": "Swift Conference 2024",
                "tagline": "The future of Swift development",
                "start_date": "2024-06-15T09:00:00Z",
                "end_date": "2024-06-17T18:00:00Z",
                "location": "San Francisco Convention Center",
                "max_attendees": 1000,
                "is_virtual_enabled": true,
                "ticket_price": 299.99,
                "speakers": [
                    "Chris Lattner",
                    "Ted Kremenek",
                    "Holly Borla"
                ],
                "venue": {
                    "name": "Moscone Center",
                    "address": "747 Howard St, San Francisco, CA 94103",
                    "capacity": 1500
                }
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let event = try JSONDecoder().decode(Object.self, from: data)
        
        // Direct, type-safe access to all metadata fields
        let eventName = event.metadata?.event_name.string
        let startDate = event.metadata?.start_date.string
        let isVirtual = event.metadata?.is_virtual_enabled.bool
        let price = event.metadata?.ticket_price.double
        
        XCTAssertEqual(eventName, "Swift Conference 2024")
        XCTAssertEqual(startDate, "2024-06-15T09:00:00Z")
        XCTAssertEqual(isVirtual, true)
        XCTAssertEqual(price, 299.99)
        
        // Working with arrays and nested objects - no casting!
        if let speakers = event.metadata?.speakers.array(of: String.self) {
            XCTAssertTrue(speakers.contains("Chris Lattner"))
        }
        
        if let venue = event.metadata?.venue.dictionary(keyType: String.self, valueType: Any.self) {
            XCTAssertEqual(venue["name"] as? String, "Moscone Center")
            XCTAssertEqual(venue["capacity"] as? Int, 1500)
        }
        
        // Check field existence
        XCTAssertTrue(event.metadata?.event_name.exists ?? false)
        XCTAssertFalse(event.metadata?.cancelled.exists ?? true)
    }
}
