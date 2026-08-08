//
//  ChatsListView.swift
//  Nearby Girlfriend Chat
//

import SwiftUI

struct ChatsListView: View {
    @Binding var selectedTab: Int
    @ObservedObject private var chatsVM = ChatsViewModel.shared
    @State private var showDeleteAllAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if chatsVM.conversations.isEmpty {
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        conversationsList
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                CustomTabBar(selectedTab: $selectedTab)
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Delete All Chats", isPresented: $showDeleteAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    chatsVM.deleteAllConversations()
                }
            } message: {
                Text("Are you sure you want to delete all conversations? This action cannot be undone.")
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Chats")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                
                Text(chatsVM.conversations.isEmpty ? "No active conversations" : "\(chatsVM.conversations.count) active \(chatsVM.conversations.count == 1 ? "conversation" : "conversations")")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            if !chatsVM.conversations.isEmpty {
                Menu {
                    Button(role: .destructive, action: {
                        showDeleteAllAlert = true
                    }) {
                        Label("Delete All", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("No Conversations Yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Start chatting with someone from\nNearby or Worldwide tabs")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    // MARK: - Conversations List
    private var conversationsList: some View {
        List {
            ForEach(chatsVM.conversations) { conversation in
                ConversationRow(conversation: conversation, destination: ChatView(girlfriend: conversation.girlfriend, source: conversation.source))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            .onDelete(perform: chatsVM.deleteConversation)
        }
        .listStyle(.plain)
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: ActiveConversation
    var destination: ChatView?
    @ObservedObject private var chatsVM = ChatsViewModel.shared
    @State private var showDeleteAlert = false
    
    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    rowContent
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive, action: {
                        showDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } else {
                rowContent
                    .contextMenu {
                        Button(role: .destructive, action: {
                            showDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .alert("Delete Chat", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                chatsVM.deleteConversation(id: conversation.id)
            }
        } message: {
            Text("Are you sure you want to delete this conversation with \(conversation.girlfriend.name)?")
        }
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(url: conversation.girlfriend.avatarUrls.primaryURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                // Online indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.girlfriend.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(formatTime(conversation.lastMessageTime))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Source badge
                    Text(conversation.source == .nearby ? "Nearby" : "World")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(conversation.source == .nearby ? .pink : .purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(conversation.source == .nearby ? Color.pink.opacity(0.15) : Color.purple.opacity(0.15))
                        )
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

#Preview {
    ChatsListView(selectedTab: .constant(1))
}

