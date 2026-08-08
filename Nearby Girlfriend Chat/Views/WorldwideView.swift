//
//  WorldwideView.swift
//  Nearby Girlfriend Chat
//

import SwiftUI

struct WorldwideView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = ExploreGirlfriendsVM()
    @ObservedObject private var chatsVM = ChatsViewModel.shared
    
    private var columns: [GridItem] {
        let count: Int
        let width = UIScreen.main.bounds.width
        if width < 600 {
            count = 2 // iPhone
        } else if width < 1000 {
            count = 3 // 11-inch iPad
        } else {
            count = 4 // 13-inch iPad
        }
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.purple.opacity(0.03),
                        Color.pink.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if viewModel.isLoading && viewModel.girlfriends.isEmpty {
                        Spacer()
                        loadingView
                        Spacer()
                    } else if viewModel.girlfriends.isEmpty {
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        girlfriendsGrid
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                CustomTabBar(selectedTab: $selectedTab)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            await viewModel.loadInitial()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Worldwide")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                
                Text("Discover profiles globally")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Discovering worldwide matches...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.6), .pink.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("No Matches Found")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Check back later for worldwide matches")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Button(action: { Task { await viewModel.loadInitial() } }) {
                Text("Refresh")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
    
    // MARK: - Grid
    // MARK: - Grid
    private var girlfriendsGrid: some View {
        ScrollView {
            // Horizontal Top Picks section
            if !viewModel.topPicks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Top Picks")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.topPicks) { gf in
                                TopPickCard(girlfriend: gf)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Standard Discover Grid
            VStack(alignment: .leading, spacing: 12) {
                Text("Discover All")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .padding(.horizontal, 16)
                    
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.girlfriends) { girlfriend in
                        WorldwideCard(girlfriend: girlfriend)
                        .onAppear {
                            // Infinite scroll
                            if girlfriend.id == viewModel.girlfriends.last?.id {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
            
            if viewModel.isLoading && !viewModel.girlfriends.isEmpty {
                ProgressView()
                    .padding()
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Top Pick Card
struct TopPickCard: View {
    let girlfriend: Girlfriend

    var body: some View {
        NavigationLink(destination: GirlfriendDetailView(girlfriend: girlfriend, source: .worldwide)) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    CachedAsyncImage(url: girlfriend.avatarUrls.primaryURL) { image in
                        image
                            .resizable()
                            .aspectRatio(0.8, contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                startPoint: .topLeading,
                                  endPoint: .bottomTrailing
                            )
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .aspectRatio(0.8, contentMode: .fill)
                    }
                    .frame(width: 150)
                    
                    // Chat Count Badge
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(girlfriend.chatCount ?? 0) chats")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(8)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(girlfriend.name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let city = girlfriend.location.city {
                        Text(city)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(8)
            }
            .frame(width: 150)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Worldwide Card
struct WorldwideCard: View {
    let girlfriend: Girlfriend

    var body: some View {
        NavigationLink(destination: GirlfriendDetailView(girlfriend: girlfriend, source: .worldwide)) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                ZStack(alignment: .topTrailing) {
                    CachedAsyncImage(url: girlfriend.avatarUrls.primaryURL) { image in
                        image
                            .resizable()
                            .aspectRatio(0.8, contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .aspectRatio(0.8, contentMode: .fill)
                    }
                    .clipped()
                    
                    // Location badge
                    if let city = girlfriend.location.city {
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 8))
                            Text(city)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(8)
                    }
                }
                
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
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
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
    }
}

#Preview {
    WorldwideView(selectedTab: .constant(2))
}

