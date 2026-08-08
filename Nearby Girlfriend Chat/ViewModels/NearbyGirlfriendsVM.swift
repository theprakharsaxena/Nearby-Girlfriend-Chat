//
//  NearbyGirlfriendsVM.swift
//  Nearby Girlfriend Chat
//

import Foundation
import Combine

@MainActor
final class NearbyGirlfriendsVM: ObservableObject {
    // MARK: - Published Properties
    @Published var girlfriends: [Girlfriend] = []
    @Published var generationStatus: GenerationStatus = .notFound
    @Published var progress: Double = 0
    @Published var generatedCount: Int = 0
    @Published var totalGirlfriends: Int = 0
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentLocation: UserLocation?
    @Published var showLocationPermissionAlert = false
    
    // MARK: - Private Properties
    private let deviceId: String
    private var pollingTimer: Timer?
    private let pollingInterval: TimeInterval = 4.0
    private var retryCount = 0
    private let maxRetries = 3
    
    // MARK: - Computed Properties
    var isGenerating: Bool {
        generationStatus.isActive
    }
    
    var hasGirlfriends: Bool {
        !girlfriends.isEmpty
    }
    
    var progressText: String {
        if totalGirlfriends > 0 {
            return "\(generatedCount) of \(totalGirlfriends)"
        }
        return "Starting..."
    }
    
    var locationText: String {
        currentLocation?.city ?? currentLocation?.state ?? "Unknown Location"
    }
    
    // MARK: - Initialization
    init() {
        self.deviceId = DeviceService.shared.deviceId
    }
    
    // MARK: - Public Methods
    
    /// Initialize the app - check existing status or start fresh
    func initialize() async {
        isLoading = true
        error = nil
        
        do {
            // First check if we have existing girlfriends
            let statusResponse = try await APIService.shared.checkStatus(deviceId: deviceId)
            
            if statusResponse.success {
                generationStatus = statusResponse.generationStatus
                generatedCount = statusResponse.generatedCount ?? 0
                totalGirlfriends = statusResponse.totalGirlfriends ?? 0
                progress = statusResponse.progress
                
                if let location = statusResponse.location {
                    currentLocation = UserLocation(
                        latitude: 0,
                        longitude: 0,
                        city: location.city,
                        state: location.state,
                        country: location.country
                    )
                }
                
                // If generation is in progress, start polling
                if generationStatus.isActive {
                    await fetchGirlfriends()
                    startPolling()
                } else if generationStatus == .completed {
                    await fetchGirlfriends()
                }
            }
        } catch {
            // No existing data, that's fine - user will trigger generation
            generationStatus = .notFound
        }
        
        isLoading = false
    }
    
    /// Request location and start generation
    func startGeneration() async {
        isLoading = true
        error = nil
        retryCount = 0
        
        do {
            // Get location
            let location = try await LocationService.shared.requestLocation()
            currentLocation = location
            
            // Start generation
            let response = try await APIService.shared.generateGirlfriends(
                deviceId: deviceId,
                latitude: location.latitude,
                longitude: location.longitude,
                city: location.city,
                state: location.state,
                country: location.country,
                totalGirlfriends: 10
            )
            
            if response.success {
                generationStatus = response.generationStatus
                generatedCount = response.generatedCount ?? 0
                totalGirlfriends = response.totalGirlfriends ?? 10
                progress = Double(generatedCount) / Double(totalGirlfriends)
                
                // Start polling for updates
                if generationStatus.isActive {
                    startPolling()
                } else if generationStatus == .completed {
                    await fetchGirlfriends()
                }
            } else {
                self.error = response.error ?? "Failed to start generation"
            }
        } catch let locationError as LocationError {
            if case .permissionDenied = locationError {
                showLocationPermissionAlert = true
            }
            self.error = locationError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Start generation using custom city/location input
    func startGeneration(customCity: String, country: String = "United States") async {
        stopPolling()
        isLoading = true
        error = nil
        retryCount = 0
        girlfriends = []
        progress = 0
        generatedCount = 0
        
        do {
            // Delete existing location based records first so we can regenerate clean
            _ = try? await APIService.shared.deleteGirlfriends(deviceId: deviceId)
            
            let customLocation = UserLocation(
                latitude: 37.7749, // Default to San Francisco coordinates
                longitude: -122.4194,
                city: customCity,
                state: "",
                country: country
            )
            currentLocation = customLocation
            
            let response = try await APIService.shared.generateGirlfriends(
                deviceId: deviceId,
                latitude: customLocation.latitude,
                longitude: customLocation.longitude,
                city: customLocation.city,
                state: customLocation.state,
                country: customLocation.country,
                totalGirlfriends: 10
            )
            
            if response.success {
                generationStatus = response.generationStatus
                generatedCount = response.generatedCount ?? 0
                totalGirlfriends = response.totalGirlfriends ?? 10
                progress = Double(generatedCount) / Double(totalGirlfriends)
                
                if generationStatus.isActive {
                    startPolling()
                } else if generationStatus == .completed {
                    await fetchGirlfriends()
                }
            } else {
                self.error = response.error ?? "Failed to start generation"
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Fetch girlfriends from the API
    func fetchGirlfriends() async {
        do {
            let response = try await APIService.shared.getGirlfriends(deviceId: deviceId)
            
            if response.success {
                girlfriends = response.data ?? []
                generationStatus = response.generationStatus
                generatedCount = response.generatedCount ?? girlfriends.count
                totalGirlfriends = response.totalGirlfriends ?? 10
                progress = response.progress
                
                // Stop polling if complete
                if response.isComplete == true {
                    stopPolling()
                }
            }
            retryCount = 0
        } catch {
            retryCount += 1
            if retryCount >= maxRetries {
                self.error = error.localizedDescription
                stopPolling()
            }
        }
    }
    
    /// Refresh - delete and regenerate
    func refresh() async {
        stopPolling()
        isLoading = true
        error = nil
        girlfriends = []
        progress = 0
        generatedCount = 0
        
        do {
            // Delete existing
            _ = try await APIService.shared.deleteGirlfriends(deviceId: deviceId)
            
            // Regenerate
            await startGeneration()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Manually check status (lightweight)
    func checkStatus() async {
        do {
            let response = try await APIService.shared.checkStatus(deviceId: deviceId)
            
            if response.success {
                generationStatus = response.generationStatus
                generatedCount = response.generatedCount ?? 0
                totalGirlfriends = response.totalGirlfriends ?? 0
                progress = response.progress
            }
        } catch {
            // Silent fail for status check
        }
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Private Methods
    
    private func startPolling() {
        stopPolling()
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchGirlfriends()
            }
        }
    }
    
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
}

// MARK: - Explore ViewModel for All Girlfriends
@MainActor
final class ExploreGirlfriendsVM: ObservableObject {
    @Published var girlfriends: [Girlfriend] = []
    @Published var topPicks: [Girlfriend] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasMorePages = true
    
    private var currentPage = 1
    private let pageSize = 30
    private var isLoadingMore = false
    
    func loadInitial() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        currentPage = 1
        
        // Load top picks and initial girlfriends in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    let response = try await APIService.shared.getTopPickGirlfriends()
                    if response.success {
                        let data = response.data ?? []
                        await MainActor.run {
                            self.topPicks = data
                        }
                    }
                } catch {
                    print("Failed to load top picks: \(error.localizedDescription)")
                }
            }
            
            group.addTask {
                do {
                    let response = try await APIService.shared.getAllGirlfriends(page: 1, limit: self.pageSize)
                    await MainActor.run {
                        if response.success {
                            self.girlfriends = response.data ?? []
                            self.hasMorePages = (response.page ?? 1) < (response.totalPages ?? 1)
                        } else {
                            self.error = response.error
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.error = error.localizedDescription
                    }
                }
            }
        }
        
        isLoading = false
    }
    
    func refresh() async {
        error = nil
        currentPage = 1
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    let response = try await APIService.shared.getTopPickGirlfriends()
                    if response.success {
                        let data = response.data ?? []
                        await MainActor.run {
                            self.topPicks = data
                        }
                    }
                } catch {
                    print("Failed to load top picks: \(error.localizedDescription)")
                }
            }
            
            group.addTask {
                do {
                    let response = try await APIService.shared.getAllGirlfriends(page: 1, limit: self.pageSize)
                    await MainActor.run {
                        if response.success {
                            self.girlfriends = response.data ?? []
                            self.hasMorePages = (response.page ?? 1) < (response.totalPages ?? 1)
                        } else {
                            self.error = response.error
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.error = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func loadMore() async {
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let response = try await APIService.shared.getAllGirlfriends(page: currentPage, limit: pageSize)
            
            if response.success {
                let newGirlfriends = response.data ?? []
                girlfriends.append(contentsOf: newGirlfriends)
                hasMorePages = (response.page ?? currentPage) < (response.totalPages ?? 1)
            }
        } catch {
            currentPage -= 1
        }
        
        isLoadingMore = false
    }
}

