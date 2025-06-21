//
//  PublishDateTests.swift
//  
//
//  Created by Test on 2024.
//

import XCTest
@testable import CosmicSDK

final class PublishDateTests: XCTestCase {
    
    func testInsertObjectWithPublishAt() {
        // Example of inserting an object with a future publish date
        // The object will be created as a draft regardless of status parameter
        
        let config = CosmicSDKSwift.Config.createBucketClient(
            bucketSlug: "your-bucket-slug",
            readKey: "your-read-key",
            writeKey: "your-write-key"
        )
        
        let sdk = CosmicSDKSwift(config)
        
        // ISO 8601 date format for future publish date
        let futureDate = "2024-12-25T00:00:00.000Z"
        
        // Insert object with publish_at - will be created as draft
        sdk.insertOne(
            type: "posts",
            title: "Holiday Announcement",
            content: "This will be published on Christmas!",
            status: .published, // This will be ignored and set to draft
            publish_at: futureDate
        ) { result in
            switch result {
            case .success(let response):
                print("Object created: \(response.message ?? "")")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    func testInsertObjectWithUnpublishAt() {
        // Example of inserting an object with an unpublish date
        
        let config = CosmicSDKSwift.Config.createBucketClient(
            bucketSlug: "your-bucket-slug",
            readKey: "your-read-key",
            writeKey: "your-write-key"
        )
        
        let sdk = CosmicSDKSwift(config)
        
        // ISO 8601 date format for unpublish date
        let unpublishDate = "2024-12-31T23:59:59.000Z"
        
        // Insert object with unpublish_at - will be created as draft
        sdk.insertOne(
            type: "promotions",
            title: "Limited Time Offer",
            content: "This promotion expires at the end of the year!",
            unpublish_at: unpublishDate
        ) { result in
            switch result {
            case .success(let response):
                print("Object created: \(response.message ?? "")")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    func testFindObjectsWithAnyStatus() {
        // Example of finding objects with any status (published && draft)
        
        let config = CosmicSDKSwift.Config.createBucketClient(
            bucketSlug: "your-bucket-slug",
            readKey: "your-read-key",
            writeKey: "your-write-key"
        )
        
        let sdk = CosmicSDKSwift(config)
        
        // Find all objects regardless of status
        sdk.find(
            type: "posts",
            status: .any // Will query for both published and draft objects
        ) { result in
            switch result {
            case .success(let response):
                print("Found \(response.objects.count) objects")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    func testUpdateObjectWithPublishDates() {
        // Example of updating an object with both publish and unpublish dates
        
        let config = CosmicSDKSwift.Config.createBucketClient(
            bucketSlug: "your-bucket-slug",
            readKey: "your-read-key",
            writeKey: "your-write-key"
        )
        
        let sdk = CosmicSDKSwift(config)
        
        let objectId = "your-object-id"
        let publishDate = "2024-12-20T00:00:00.000Z"
        let unpublishDate = "2024-12-27T00:00:00.000Z"
        
        // Update object with both dates - will be set to draft
        sdk.updateOne(
            type: "events",
            id: objectId,
            title: "Week-long Holiday Event",
            publish_at: publishDate,
            unpublish_at: unpublishDate
        ) { result in
            switch result {
            case .success(let response):
                print("Object updated: \(response.message ?? "")")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
} 