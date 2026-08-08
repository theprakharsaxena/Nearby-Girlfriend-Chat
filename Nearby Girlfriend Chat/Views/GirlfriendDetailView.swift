//
//  GirlfriendDetailView.swift
//  Nearby Girlfriend Chat
//

import SwiftUI

struct GirlfriendDetailView: View {
    let girlfriend: Girlfriend
    var source: ActiveConversation.ConversationSource = .nearby
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var chatsVM = ChatsViewModel.shared
    @State private var currentImageIndex = 0
    @State private var navigateToChat = false
    
    private var images: [URL] {
        [girlfriend.avatarUrls.primaryURL, girlfriend.avatarUrls.secondaryURL].compactMap { $0 }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(spacing: 0) {
                    // Image Carousel
                    ZStack(alignment: .top) {
                        TabView(selection: $currentImageIndex) {
                            ForEach(images.indices, id: \.self) { index in
                                CachedAsyncImage(url: images[index]) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    placeholderImage
                                }
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .aspectRatio(0.8, contentMode: .fit)
                        
                        // Gradient overlay
                        VStack {
                            Spacer()
                            LinearGradient(
                                colors: [.clear, Color(.systemBackground)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                        }
                    }
                    
                    // Profile Info
                    VStack(alignment: .leading, spacing: 20) {
                        // Name and Age
                        HStack(alignment: .firstTextBaseline) {
                            Text(girlfriend.name)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            
                            Text(girlfriend.age)
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Online status
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                Text("Online")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // Location
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.pink)
                            
                            Text(girlfriend.location.displayText)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        // Personality
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Personality", systemImage: "sparkles")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text(girlfriend.personality)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        
                        // About
                        VStack(alignment: .leading, spacing: 8) {
                            Label("About", systemImage: "person.text.rectangle")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text(girlfriend.description)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        
                        // Interests
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Interests", systemImage: "heart.fill")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(girlfriend.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.pink)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(Color.pink.opacity(0.12))
                                        )
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -40)
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Sticky Header controls
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Page indicator (floats top right)
                if images.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(images.indices, id: \.self) { index in
                            Circle()
                                .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            // Chat button
            Button(action: startChatting) {
                HStack(spacing: 10) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Start Chatting")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .pink.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .allowsHitTesting(false),
                alignment: .bottom
            )
        }
        .navigationDestination(isPresented: $navigateToChat) {
            ChatView(girlfriend: girlfriend, source: source)
        }
    }
    
    private func startChatting() {
        // Register the conversation
        _ = chatsVM.startConversation(with: girlfriend, source: source)
        // Navigate to chat
        navigateToChat = true
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "person.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// Simple Flow Layout for interests
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        let containerWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    NavigationStack {
        GirlfriendDetailView(
            girlfriend: Girlfriend(
                id: "1",
                name: "Sofia Martinez",
                age: "24",
                personality: "Adventurous and spontaneous, always ready for new experiences",
                interests: ["Hiking", "Photography", "Travel", "Coffee", "Music", "Art"],
                description: "A free-spirited soul who loves exploring new places and meeting new people. I believe life is too short to stay in one place, so I'm always planning my next adventure. When I'm not traveling, you can find me at a local coffee shop with my camera, capturing the beauty in everyday moments.",
                location: GirlfriendLocation(city: "San Francisco", state: "California", country: "USA"),
                avatarUrls: AvatarUrls(image1: "https://picsum.photos/400/600", image2: "https://picsum.photos/400/601"),
                prompt: ""
            ),
            source: .nearby
        )
    }
}
