//
//  APIResponse.swift
//  Nearby Girlfriend Chat
//

import Foundation

// MARK: - Generate Response
struct GenerateResponse: Codable {
    let success: Bool
    let message: String?
    let status: String?
    let generatedCount: Int?
    let totalGirlfriends: Int?
    let error: String?
    
    var generationStatus: GenerationStatus {
        guard let statusString = status else { return .notFound }
        return GenerationStatus(rawValue: statusString) ?? .notFound
    }
}

// MARK: - Girlfriends List Response
struct GirlfriendsResponse: Codable {
    let success: Bool
    let status: String?
    let generatedCount: Int?
    let totalGirlfriends: Int?
    let isComplete: Bool?
    let data: [Girlfriend]?
    let error: String?
    
    var generationStatus: GenerationStatus {
        guard let statusString = status else { return .notFound }
        return GenerationStatus(rawValue: statusString) ?? .notFound
    }
    
    var progress: Double {
        guard let total = totalGirlfriends, total > 0 else { return 0 }
        return Double(generatedCount ?? 0) / Double(total)
    }
}

// MARK: - Status Response
struct StatusResponse: Codable {
    let success: Bool
    let status: String?
    let generatedCount: Int?
    let totalGirlfriends: Int?
    let isComplete: Bool?
    let location: GirlfriendLocation?
    let error: String?
    
    var generationStatus: GenerationStatus {
        guard let statusString = status else { return .notFound }
        return GenerationStatus(rawValue: statusString) ?? .notFound
    }
    
    var progress: Double {
        guard let total = totalGirlfriends, total > 0 else { return 0 }
        return Double(generatedCount ?? 0) / Double(total)
    }
}

// MARK: - All Girlfriends Response (Paginated)
struct AllGirlfriendsResponse: Codable {
    let success: Bool
    let total: Int?
    let page: Int?
    let limit: Int?
    let totalPages: Int?
    let data: [Girlfriend]?
    let error: String?
}

// MARK: - Delete Response
struct DeleteResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

// MARK: - Generate Request
struct GenerateRequest: Codable {
    let deviceId: String
    let latitude: Double
    let longitude: Double
    let city: String?
    let state: String?
    let country: String?
    let totalGirlfriends: Int?
}

