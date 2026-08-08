//
//  GirlfriendCardView.swift
//  Nearby Girlfriend Chat
//

import SwiftUI

// Custom button style that scales on press without blocking scroll gestures
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct GirlfriendCardView: View {
    let girlfriend: Girlfriend
    var destination: GirlfriendDetailView?

    init(girlfriend: Girlfriend, destination: GirlfriendDetailView? = nil) {
        self.girlfriend = girlfriend
        self.destination = destination
    }

    init(girlfriend: Girlfriend, onTap: @escaping () -> Void) {
        self.girlfriend = girlfriend
        self.destination = nil
        // For backwards compatibility, we'll handle this with a deprecated onTap
        // But for iOS 16 compatibility, prefer using the destination parameter
    }
    
    @State private var imageLoaded = false

    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    cardContent
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                Button(action: {}) {
                    cardContent
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private var cardContent: some View {
            ZStack(alignment: .bottom) {
                // Background Image
                CachedAsyncImage(url: girlfriend.avatarUrls.primaryURL) { image in
                    image
                        .resizable()
                        .aspectRatio(0.8, contentMode: .fill)
                        .onAppear { withAnimation(.easeOut(duration: 0.3)) { imageLoaded = true } }
                } placeholder: {
                    placeholderView
                        .aspectRatio(0.8, contentMode: .fill)
                }
                
                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                
                // Info Overlay
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(girlfriend.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(girlfriend.age)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        // Online indicator
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    
                    // Location
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.pink)
                        
                        Text(girlfriend.location.displayText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    // Interests Tags - Use HStack instead of ScrollView to avoid gesture conflicts
                    HStack(spacing: 6) {
                        ForEach(girlfriend.interests.prefix(3), id: \.self) { interest in
                            Text(interest)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.pink.opacity(0.6))
                                )
                        }
                        Spacer()
                    }
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .opacity(imageLoaded ? 1 : 0.7)
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "person.fill")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.5))
        }
        .aspectRatio(0.8, contentMode: .fill)
    }

// Compact card for grid view
struct GirlfriendCompactCard: View {
    let girlfriend: Girlfriend
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                CachedAsyncImage(url: girlfriend.avatarUrls.primaryURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 160)
                .clipped()
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(girlfriend.name)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(girlfriend.age)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(girlfriend.personality)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(10)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        GirlfriendCardView(
            girlfriend: Girlfriend(
                id: "1",
                name: "Sofia Martinez",
                age: "24",
                personality: "Adventurous and spontaneous",
                interests: ["Hiking", "Photography", "Travel"],
                description: "A free-spirited soul...",
                location: GirlfriendLocation(city: "San Francisco", state: "California", country: "USA"),
                avatarUrls: AvatarUrls(image1: "https://picsum.photos/400/600", image2: nil),
                prompt: ""
            )
        )
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}

