//
//  MetadataCleanAPITests.swift
//  
//
//  Created to demonstrate the cleanest metadata API usage
//

import XCTest
@testable import CosmicSDK

final class MetadataCleanAPITests: XCTestCase {
    
    func testDirectComparison() throws {
        let json = """
        {
            "title": "Product",
            "metadata": {
                "name": "iPhone 15 Pro",
                "price": 999.99,
                "in_stock": true,
                "quantity": 42
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let product = try JSONDecoder().decode(Object.self, from: data)
        
        // Direct comparisons - the cleanest possible API!
        XCTAssertTrue(product.metadata?.name == "iPhone 15 Pro")
        XCTAssertTrue(product.metadata?.price == 999.99)
        XCTAssertTrue(product.metadata?.in_stock == true)
        XCTAssertTrue(product.metadata?.quantity == 42)
        
        // Works in if statements
        if product.metadata?.in_stock == true {
            print("Product is in stock!")
        }
        
        // Works in guard statements
        guard product.metadata?.quantity == 42 else {
            XCTFail("Quantity should be 42")
            return
        }
    }
    
    func testConditionalUsage() throws {
        let json = """
        {
            "title": "User",
            "metadata": {
                "username": "johndoe",
                "premium": true,
                "credits": 100
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let user = try JSONDecoder().decode(Object.self, from: data)
        
        // Clean conditional checks
        if user.metadata?.premium == true {
            // Premium user logic
            XCTAssertTrue(true)
        }
        
        // Numeric comparisons need explicit type access
        if let credits = user.metadata?.credits.int, credits > 50 {
            // User has enough credits
            XCTAssertTrue(true)
        }
        
        // String checks
        if user.metadata?.username == "johndoe" {
            // Correct user
            XCTAssertTrue(true)
        }
    }
    
    func testNestedAccess() throws {
        let json = """
        {
            "title": "Company",
            "metadata": {
                "name": "Acme Corp",
                "address": {
                    "street": "123 Main St",
                    "city": "San Francisco",
                    "zip": "94105"
                },
                "employees": 150
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let company = try JSONDecoder().decode(Object.self, from: data)
        
        // Direct nested access
        XCTAssertEqual(company.metadata?.address.city, "San Francisco")
        XCTAssertEqual(company.metadata?.address.zip, "94105")
        
        // Check existence
        XCTAssertTrue(company.metadata?.address.exists ?? false)
        XCTAssertFalse(company.metadata?.nonexistent.exists ?? true)
    }
    
    func testVariableAssignment() throws {
        let json = """
        {
            "title": "Event",
            "metadata": {
                "title": "SwiftUI Workshop",
                "date": "2024-03-15",
                "price": 299.0,
                "is_online": true
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let event = try JSONDecoder().decode(Object.self, from: data)
        
        // When you need to store values, use typed accessors
        let eventTitle: String? = event.metadata?.title.string
        let eventDate: String? = event.metadata?.date.string
        let eventPrice: Double? = event.metadata?.price.double
        let isOnline: Bool? = event.metadata?.is_online.bool
        
        XCTAssertEqual(eventTitle, "SwiftUI Workshop")
        XCTAssertEqual(eventDate, "2024-03-15")
        XCTAssertEqual(eventPrice, 299.0)
        XCTAssertEqual(isOnline, true)
        
        // Or use type inference with explicit property access
        let title = event.metadata?.title.stringValue
        let price = event.metadata?.price.doubleValue
        
        XCTAssertEqual(title, "SwiftUI Workshop")
        XCTAssertEqual(price, 299.0)
    }
}
