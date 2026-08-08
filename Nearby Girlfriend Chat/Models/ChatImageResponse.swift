//
//  ChatImageResponse.swift
//  Nearby Girlfriend Chat
//

import Foundation

struct ChatImageResponse: Codable {
    let success: Bool
    let image: String?
    let error: String?
    let details: String?
}
