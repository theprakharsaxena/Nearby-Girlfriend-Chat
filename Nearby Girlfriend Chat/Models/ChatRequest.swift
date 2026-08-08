//
//  ChatRequest.swift
//  Nearby Girlfriend Chat
//

import Foundation

struct ChatRequest: Codable {
    let deviceId: String
    let conversationId: String
    let message: String
    let name: String
    let age: String
    let personality: String
    let prompt: String
    let location: String
    let girlfriendId: String
    let version: String
}

