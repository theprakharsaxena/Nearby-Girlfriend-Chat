//
//  APIService.swift
//  Nearby Girlfriend Chat
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case noData
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .noData:
            return "No data received"
        case .rateLimited:
            return "Please wait before trying again"
        }
    }
}

actor APIService {
    static let shared = APIService()
    
    private let baseURL = "https://nearby-backend-api.vercel.app"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }
    
    // MARK: - Generate Girlfriends
    /// POST /api/nearby-girlfriends/generate
    func generateGirlfriends(
        deviceId: String,
        latitude: Double,
        longitude: Double,
        city: String? = nil,
        state: String? = nil,
        country: String? = nil,
        totalGirlfriends: Int = 10
    ) async throws -> GenerateResponse {
        let url = URL(string: "\(baseURL)/api/nearby-girlfriends/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = GenerateRequest(
            deviceId: deviceId,
            latitude: latitude,
            longitude: longitude,
            city: city,
            state: state,
            country: country,
            totalGirlfriends: totalGirlfriends
        )
        
        request.httpBody = try encoder.encode(payload)
        
        return try await performRequest(request)
    }
    
    // MARK: - Get Girlfriends
    /// GET /api/nearby-girlfriends/:deviceId
    func getGirlfriends(deviceId: String) async throws -> GirlfriendsResponse {
        let url = URL(string: "\(baseURL)/api/nearby-girlfriends/\(deviceId)")!
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        return try await performRequest(request)
    }
    
    // MARK: - Check Status
    /// GET /api/nearby-girlfriends/status/:deviceId
    func checkStatus(deviceId: String) async throws -> StatusResponse {
        let url = URL(string: "\(baseURL)/api/nearby-girlfriends/status/\(deviceId)")!
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        return try await performRequest(request)
    }
    
    // MARK: - Get All Girlfriends (Paginated)
    /// GET /api/nearby-girlfriends/all/list
    func getAllGirlfriends(page: Int = 1, limit: Int = 30) async throws -> AllGirlfriendsResponse {
        var components = URLComponents(string: "\(baseURL)/api/nearby-girlfriends/all/list")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        var request = URLRequest(url: components.url!)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        return try await performRequest(request)
    }
    
    // MARK: - Get Top Pick Girlfriends
    /// GET /api/girlfriends/toppicks
    func getTopPickGirlfriends() async throws -> GirlfriendsResponse {
        let url = URL(string: "\(baseURL)/api/girlfriends/toppicks")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        
        return try await performRequest(request)
    }
    
    // MARK: - Delete Girlfriends
    /// DELETE /api/nearby-girlfriends/:deviceId
    func deleteGirlfriends(deviceId: String) async throws -> DeleteResponse {
        let url = URL(string: "\(baseURL)/api/nearby-girlfriends/\(deviceId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        return try await performRequest(request)
    }
    
    // MARK: - Chat API
    /// POST /api/chat/text/byversion
    func sendChatMessage(
        deviceId: String,
        conversationId: String,
        message: String,
        name: String,
        age: String,
        personality: String,
        prompt: String,
        location: String,
        girlfriendId: String,
        version: String = "1.0.0"
    ) async throws -> ChatResponse {
        let url = URL(string: "\(baseURL)/api/chat/text/byversion")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let payload = ChatRequest(
            deviceId: deviceId,
            conversationId: conversationId,
            message: message,
            name: name,
            age: age,
            personality: personality,
            prompt: prompt,
            location: location,
            girlfriendId: girlfriendId,
            version: version
        )
        
        request.httpBody = try encoder.encode(payload)
        
        return try await performRequest(request)
    }
    
    /// POST /api/chat/image/byversion
    func sendChatImageMessage(
        message: String,
        age: String,
        personality: String,
        location: String,
        girlfriendId: String,
        generateImage: Bool = true,
        version: String = "1.0.0"
    ) async throws -> ChatImageResponse {
        let url = URL(string: "\(baseURL)/api/chat/image/byversion")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45 // Image generation might take a bit longer
        
        let payload = ChatImageRequest(
            message: message,
            age: age,
            personality: personality,
            location: location,
            girlfriendId: girlfriendId,
            generateImage: generateImage,
            version: version
        )
        
        request.httpBody = try encoder.encode(payload)
        
        return try await performRequest(request)
    }
    
    // MARK: - Private Helpers
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.noData
            }
            
            if httpResponse.statusCode == 429 {
                throw APIError.rateLimited
            }
            
            if httpResponse.statusCode >= 500 {
                throw APIError.serverError("Server is temporarily unavailable")
            }
            
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                // Try to extract error message from response
                if let errorResponse = try? decoder.decode(ErrorOnlyResponse.self, from: data),
                   let errorMessage = errorResponse.error {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// Helper struct for error-only responses
private struct ErrorOnlyResponse: Decodable {
    let success: Bool
    let error: String?
}

