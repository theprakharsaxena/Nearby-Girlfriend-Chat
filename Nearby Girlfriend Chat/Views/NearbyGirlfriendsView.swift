//
//  NearbyGirlfriendsView.swift
//  Nearby Girlfriend Chat
//

import SwiftUI

struct NearbyGirlfriendsView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = NearbyGirlfriendsVM()
    @State private var showCustomLocationAlert = false
    @State private var customCityInput = ""
    @State private var customCountryInput = "United States"
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 450), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // Content
                    if viewModel.isLoading && !viewModel.hasGirlfriends {
                        loadingView
                    } else if viewModel.isGenerating && !viewModel.hasGirlfriends {
                        generatingView
                    } else if viewModel.hasGirlfriends {
                        girlfriendsListView
                    } else {
                        emptyStateView
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .alert("Location Access Required", isPresented: $viewModel.showLocationPermissionAlert) {
            Button("Open Settings") {
                LocationService.shared.openSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable location access in Settings to find matches near you.")
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
            if viewModel.generationStatus == .failed {
                Button("Retry") {
                    Task { await viewModel.refresh() }
                }
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .alert("Enter Custom Location", isPresented: $showCustomLocationAlert) {
            TextField("City (e.g. London, Paris)", text: $customCityInput)
            TextField("Country (e.g. UK, France)", text: $customCountryInput)
            
            Button("Search") {
                let city = customCityInput.trimmingCharacters(in: .whitespacesAndNewlines)
                let country = customCountryInput.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if city.isEmpty || country.isEmpty {
                    viewModel.error = "You need to fill in both the City and Country details."
                } else {
                    Task {
                        await viewModel.startGeneration(customCity: city, country: country)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                customCityInput = ""
                customCountryInput = ""
            }
        } message: {
            Text("Enter a city and country to find AI matches in that specific area.")
        }
        .task {
            await viewModel.initialize()
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.pink.opacity(0.03),
                Color.purple.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nearby")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                if let location = viewModel.currentLocation {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.pink)
                        
                        Text(location.city ?? location.state ?? "Your Area")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Progress indicator (when generating)
            if viewModel.isGenerating && viewModel.hasGirlfriends {
                MiniProgressIndicator(
                    progress: viewModel.progress,
                    count: viewModel.generatedCount,
                    total: viewModel.totalGirlfriends
                )
            }
            
            // Refresh button
            Menu {
                Button(action: { Task { await viewModel.refresh() } }) {
                    Label("Find New Matches", systemImage: "arrow.clockwise")
                }
                Button(action: { showCustomLocationAlert = true }) {
                    Label("Change Location", systemImage: "location.magnifyingglass")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Generating View
    private var generatingView: some View {
        VStack {
            Spacer()
            
            GenerationProgressView(
                progress: viewModel.progress,
                generatedCount: viewModel.generatedCount,
                totalCount: viewModel.totalGirlfriends,
                status: viewModel.generationStatus,
                locationText: viewModel.locationText
            )
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(0.15), .purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Find Your Match")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                Text("Discover AI companions nearby who share your interests and are ready to chat")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: { Task { await viewModel.startGeneration() } }) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Start Matching")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(width: 220, height: 56)
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
            .disabled(viewModel.isLoading)
            
            Spacer()
        }
    }
    
    // MARK: - Girlfriends List
    private var girlfriendsListView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.girlfriends) { girlfriend in
                    GirlfriendCardView(girlfriend: girlfriend, destination: GirlfriendDetailView(girlfriend: girlfriend, source: .nearby))
                    .padding(.horizontal, 8)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 12)
            
            // Show generating indicator at the bottom if still in progress
            if viewModel.isGenerating {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Finding more matches...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .refreshable {
            await viewModel.fetchGirlfriends()
        }
    }
}

#Preview {
    NearbyGirlfriendsView(selectedTab: .constant(0))
}
