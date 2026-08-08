//
//  ChatImageRequest.swift
//  Nearby Girlfriend Chat
//

import Foundation

struct ChatImageRequest: Codable {
    let message: String
    let age: String
    let personality: String
    let location: String
    let girlfriendId: String
    let generateImage: Bool
    let version: String
}
