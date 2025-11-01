import CosmicSDK

// MARK: - MongoDB-Style Query Filter Examples
// This file demonstrates the new query filter functionality

class QueryFilterExamples {

    let cosmic = CosmicSDKSwift(
        .createBucketClient(
            bucketSlug: "your-bucket-slug",
            readKey: "your-read-key",
            writeKey: "your-write-key"
        )
    )

    // MARK: - Example 1: Filter by Single Relationship ID
    func fetchEpisodesByHost(hostId: String) async throws {
        let response = try await cosmic.find(
            type: "episode",
            query: ["metadata.regular_hosts.id": hostId],
            depth: 2
        )

        print("Found \(response.objects.count) episodes for host \(hostId)")
    }

    // MARK: - Example 2: Filter by Multiple Relationship IDs ($in operator)
    func fetchEpisodesByMultipleHosts(hostIds: [String]) async throws {
        let response = try await cosmic.find(
            type: "episode",
            query: [
                "metadata.regular_hosts.id": ["$in": hostIds]
            ],
            props: "id,slug,title,content,metadata",
            limit: 20,
            depth: 2
        )

        print("Found \(response.objects.count) episodes for \(hostIds.count) hosts")
    }

    // MARK: - Example 3: Filter by Date Range
    func fetchRecentEpisodes(since date: String) async throws {
        let response = try await cosmic.find(
            type: "episode",
            query: [
                "metadata.broadcast_date": ["$gte": date]
            ],
            limit: 10,
            sort: .createdDescending
        )

        print("Found \(response.objects.count) episodes since \(date)")
    }

    // MARK: - Example 4: Check Field Existence
    func fetchEpisodesWithTakeovers() async throws {
        let response = try await cosmic.find(
            type: "episode",
            query: [
                "metadata.takeovers": ["$exists": true]
            ]
        )

        print("Found \(response.objects.count) episodes with takeovers")
    }

    // MARK: - Example 5: Complex Query with Multiple Filters
    func fetchFilteredEpisodes(
        hostIds: [String],
        startDate: String,
        endDate: String
    ) async throws {
        let response = try await cosmic.find(
            type: "episode",
            query: [
                "metadata.regular_hosts.id": ["$in": hostIds],
                "metadata.broadcast_date": ["$gte": startDate, "$lte": endDate],
                "status": "published"
            ],
            depth: 2
        )

        print("Found \(response.objects.count) filtered episodes")
    }

    // MARK: - Example 6: Using Completion Handlers (Backward Compatibility)
    func fetchEpisodesByHostWithCompletion(hostId: String, completion: @escaping (Result<[Object], Error>) -> Void) {
        cosmic.find(
            type: "episode",
            query: ["metadata.regular_hosts.id": hostId],
            depth: 2
        ) { results in
            switch results {
            case .success(let response):
                completion(.success(response.objects))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Example 7: Comparison with Regex (Before vs After)

    // OLD WAY: Using regex for exact ID match
    func fetchEpisodesByHostOldWay(hostId: String) async throws {
        let response = try await cosmic.findRegex(
            type: "episode",
            field: "metadata.regular_hosts.id",
            pattern: "^\(hostId)$",  // Exact match regex - less efficient
            depth: 2
        )

        // Required client-side filtering to verify results
        let matchingEpisodes = response.objects.filter { object in
            guard let hostObjects = object.metadata?.regular_hosts.raw as? [[String: Any]] else {
                return false
            }
            let episodeHostIds = hostObjects.compactMap { $0["id"] as? String }
            return episodeHostIds.contains(hostId)
        }

        print("Found \(matchingEpisodes.count) matching episodes (old way)")
    }

    // NEW WAY: Using query filters
    func fetchEpisodesByHostNewWay(hostId: String) async throws {
        let response = try await cosmic.find(
            type: "episode",
            query: ["metadata.regular_hosts.id": hostId],  // Direct filter - more efficient
            depth: 2
        )

        // No client-side filtering needed!
        print("Found \(response.objects.count) matching episodes (new way)")
    }

    // MARK: - Example 8: Range Queries
    func fetchProductsByPriceRange(minPrice: Double, maxPrice: Double) async throws {
        let response = try await cosmic.find(
            type: "products",
            query: [
                "metadata.price": [
                    "$gte": minPrice,
                    "$lte": maxPrice
                ]
            ]
        )

        print("Found \(response.objects.count) products in price range $\(minPrice)-$\(maxPrice)")
    }

    // MARK: - Example 9: Not Equal Filter
    func fetchActiveProducts() async throws {
        let response = try await cosmic.find(
            type: "products",
            query: [
                "metadata.status": ["$ne": "discontinued"]
            ]
        )

        print("Found \(response.objects.count) active products")
    }

    // MARK: - Example 10: Pagination with Query Filters
    func fetchPagedEpisodesByHost(
        hostId: String,
        page: Int,
        pageSize: Int
    ) async throws {
        let skip = page * pageSize

        let response = try await cosmic.find(
            type: "episode",
            query: ["metadata.regular_hosts.id": hostId],
            limit: pageSize,
            skip: skip,
            depth: 2
        )

        print("Page \(page + 1): Found \(response.objects.count) episodes")
    }
}
