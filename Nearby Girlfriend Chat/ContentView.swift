//
//  ContentView.swift
//  Nearby Girlfriend Chat
//
//  Created by Prakhar Saxena on 24/12/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var showSplash = true
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            MainTabView(selectedTab: $selectedTab)
                .opacity(showSplash ? 0 : 1)
            
            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Animate splash screen away after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Reusable Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 8) {
            tabButton(title: "Nearby", image: "location.fill", tag: 0)
            tabButton(title: "Chats", image: "bubble.left.and.bubble.right.fill", tag: 1)
            tabButton(title: "Worldwide", image: "globe", tag: 2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
        .padding(.bottom, 10)
    }
    
    private func tabButton(title: String, image: String, tag: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = tag
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: image)
                    .font(.system(size: 15, weight: .semibold))
                
                if selectedTab == tag {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
            }
            .foregroundColor(selectedTab == tag ? .white : .primary.opacity(0.75))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selectedTab == tag ? Color.pink : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            NearbyGirlfriendsView(selectedTab: $selectedTab)
                .opacity(selectedTab == 0 ? 1 : 0)
                .disabled(selectedTab != 0)
            
            ChatsListView(selectedTab: $selectedTab)
                .opacity(selectedTab == 1 ? 1 : 0)
                .disabled(selectedTab != 1)
            
            WorldwideView(selectedTab: $selectedTab)
                .opacity(selectedTab == 2 ? 1 : 0)
                .disabled(selectedTab != 2)
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0
    @State private var heartBeat = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.pink.opacity(0.8),
                    Color.purple.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background circles
            GeometryReader { geometry in
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: CGFloat.random(in: 100...300))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 20)
                }
            }
            
            // Content
            VStack(spacing: 20) {
                // App icon / Logo
                ZStack {
                    // Pulse effect
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .scaleEffect(heartBeat ? 1.2 : 1)
                        .opacity(heartBeat ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.0)
                                .repeatForever(autoreverses: false),
                            value: heartBeat
                        )
                    
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .scaleEffect(heartBeat ? 1.05 : 1)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true),
                            value: heartBeat
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Nearby")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Girlfriend Chat")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Text("Find your perfect match nearby")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 8)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            heartBeat = true
        }
    }
}

#Preview {
    ContentView()
}
