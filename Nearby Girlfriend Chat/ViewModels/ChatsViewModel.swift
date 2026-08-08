//
//  ChatsViewModel.swift
//  Nearby Girlfriend Chat
//

import Foundation
import SwiftUI
import Combine

// Represents an active conversation
struct ActiveConversation: Identifiable, Codable, Hashable {
    let id: String  // Used for UI identification (girlfriend.id)
    let conversationId: String  // Unique conversation ID (deviceId + timestamp)
    let girlfriend: Girlfriend
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
    var source: ConversationSource
    
    enum ConversationSource: String, Codable {
        case nearby
        case worldwide
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ActiveConversation, rhs: ActiveConversation) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class ChatsViewModel: ObservableObject {
    static let shared = ChatsViewModel()
    
    @Published var conversations: [ActiveConversation] = []
    @Published var selectedConversation: ActiveConversation?
    
    private let userDefaults = UserDefaults.standard
    private let conversationsKey = "activeConversations"
    private let deviceId = DeviceService.shared.deviceId
    
    private init() {
        loadConversations()
    }
    
    // Start or open a conversation with a girlfriend
    func startConversation(with girlfriend: Girlfriend, source: ActiveConversation.ConversationSource) -> ActiveConversation {
        // Check if conversation already exists
        if let existingIndex = conversations.firstIndex(where: { $0.girlfriend.id == girlfriend.id }) {
            let existing = conversations[existingIndex]
            // Move to top of list
            conversations.remove(at: existingIndex)
            conversations.insert(existing, at: 0)
            saveConversations()
            return existing
        }
        
        // Generate unique conversation ID: deviceId + timestamp
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000) // milliseconds
        let conversationId = "\(deviceId)_\(timestamp)"
        
        // Create new conversation
        let newConversation = ActiveConversation(
            id: girlfriend.id,
            conversationId: conversationId,
            girlfriend: girlfriend,
            lastMessage: "Start chatting...",
            lastMessageTime: Date(),
            unreadCount: 0,
            source: source
        )
        
        conversations.insert(newConversation, at: 0)
        saveConversations()
        return newConversation
    }
    
    // Update the last message in a conversation
    func updateLastMessage(for girlfriendId: String, message: String) {
        if let index = conversations.firstIndex(where: { $0.girlfriend.id == girlfriendId }) {
            conversations[index].lastMessage = message
            conversations[index].lastMessageTime = Date()
            
            // Move to top
            let conversation = conversations.remove(at: index)
            conversations.insert(conversation, at: 0)
            saveConversations()
        }
    }
    
    // Check if a conversation exists
    func hasConversation(with girlfriendId: String) -> Bool {
        conversations.contains { $0.girlfriend.id == girlfriendId }
    }
    
    // Get conversation for a girlfriend
    func getConversation(for girlfriendId: String) -> ActiveConversation? {
        conversations.first { $0.girlfriend.id == girlfriendId }
    }
    
    // Delete a conversation by index set (for swipe to delete)
    func deleteConversation(at offsets: IndexSet) {
        conversations.remove(atOffsets: offsets)
        saveConversations()
    }
    
    // Delete a specific conversation by ID
    func deleteConversation(id: String) {
        conversations.removeAll { $0.id == id }
        saveConversations()
    }
    
    // Delete all conversations
    func deleteAllConversations() {
        conversations.removeAll()
        saveConversations()
    }
    
    // MARK: - Persistence
    
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            userDefaults.set(encoded, forKey: conversationsKey)
        }
    }
    
    private func loadConversations() {
        if let data = userDefaults.data(forKey: conversationsKey),
           let decoded = try? JSONDecoder().decode([ActiveConversation].self, from: data) {
            conversations = decoded
        }
    }
    
    // MARK: - Message Persistence
    
    func saveMessages(_ messages: [ChatMessage], for conversationId: String) {
        if let encoded = try? JSONEncoder().encode(messages) {
            userDefaults.set(encoded, forKey: "messages_\(conversationId)")
        }
    }
    
    func loadMessages(for conversationId: String) -> [ChatMessage] {
        guard let data = userDefaults.data(forKey: "messages_\(conversationId)"),
              let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return []
        }
        return decoded
    }
}

