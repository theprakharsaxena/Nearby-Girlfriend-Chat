//
//  ChatResponse.swift
//  Nearby Girlfriend Chat
//

import Foundation

struct ChatResponse: Codable {
    let message: String?
    let source: String?
    let error: String?
    let details: String?
}

