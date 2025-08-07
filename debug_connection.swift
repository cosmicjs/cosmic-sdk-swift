#!/usr/bin/env swift

import Foundation

// Simple script to test Cosmic API connection
// Run with: swift debug_connection.swift

// Replace these with your actual values
let BUCKET_SLUG = "your-bucket-slug"
let READ_KEY = "your-read-key"

// Create a simple HTTP client
func testCosmicAPI() {
    let urlString = "https://api.cosmicjs.com/v3/buckets/\(BUCKET_SLUG)?read_key=\(READ_KEY)"
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }
        
        if let data = data {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response: \(jsonString)")
            } else {
                print("Could not decode response as UTF-8")
            }
        }
    }
    
    task.resume()
}

print("Testing Cosmic API connection...")
testCosmicAPI()

// Keep the script running to see the response
RunLoop.main.run(until: Date().addingTimeInterval(5))
