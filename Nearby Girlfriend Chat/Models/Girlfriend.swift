//
//  Girlfriend.swift
//  Nearby Girlfriend Chat
//

import Foundation

struct Girlfriend: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let age: String
    let personality: String
    let interests: [String]
    let description: String
    let location: GirlfriendLocation
    let avatarUrls: AvatarUrls
    let prompt: String
    let chatCount: Int?
    
    init(id: String, name: String, age: String, personality: String, interests: [String], description: String, location: GirlfriendLocation, avatarUrls: AvatarUrls, prompt: String, chatCount: Int? = 0) {
        self.id = id
        self.name = name
        self.age = age
        self.personality = personality
        self.interests = interests
        self.description = description
        self.location = location
        self.avatarUrls = avatarUrls
        self.prompt = prompt
        self.chatCount = chatCount
    }
    
    // For Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Girlfriend, rhs: Girlfriend) -> Bool {
        lhs.id == rhs.id
    }
}

struct GirlfriendLocation: Codable, Hashable {
    let city: String?
    let state: String?
    let country: String?
    
    var displayText: String {
        [city, state, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

struct AvatarUrls: Codable, Hashable {
    let image1: String?
    let image2: String?
    
    var primaryURL: URL? {
        if let urlString = image1 {
            return URL(string: urlString)
        }
        return nil
    }
    
    var secondaryURL: URL? {
        if let urlString = image2 {
            return URL(string: urlString)
        }
        return nil
    }
}

