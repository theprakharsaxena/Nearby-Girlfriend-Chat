//
//  LocationService.swift
//  Nearby Girlfriend Chat
//

import Foundation
import CoreLocation
import Combine
import UIKit

struct UserLocation {
    let latitude: Double
    let longitude: Double
    let city: String?
    let state: String?
    let country: String?
    
    static let empty = UserLocation(
        latitude: 0,
        longitude: 0,
        city: nil,
        state: nil,
        country: nil
    )
}

enum LocationError: Error, LocalizedError {
    case permissionDenied
    case permissionRestricted
    case locationUnavailable
    case geocodingFailed
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access denied. Please enable in Settings."
        case .permissionRestricted:
            return "Location access is restricted on this device."
        case .locationUnavailable:
            return "Unable to determine your location."
        case .geocodingFailed:
            return "Unable to determine your city."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var currentLocation: UserLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var error: LocationError?
    
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() async throws -> UserLocation {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Check authorization
        switch locationManager.authorizationStatus {
        case .notDetermined:
            requestPermission()
            // Wait briefly for permission response
            try await Task.sleep(nanoseconds: 500_000_000)
            return try await requestLocation()
            
        case .denied:
            throw LocationError.permissionDenied
            
        case .restricted:
            throw LocationError.permissionRestricted
            
        case .authorizedWhenInUse, .authorizedAlways:
            break
            
        @unknown default:
            break
        }
        
        // Get location
        let clLocation = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocation, Error>) in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()
        }
        
        // Reverse geocode
        let userLocation = try await reverseGeocode(clLocation)
        currentLocation = userLocation
        return userLocation
    }
    
    private func reverseGeocode(_ location: CLLocation) async throws -> UserLocation {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let placemark = placemarks.first
            
            return UserLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                city: placemark?.locality,
                state: placemark?.administrativeArea,
                country: placemark?.country
            )
        } catch {
            // Return location without geocoded info if geocoding fails
            return UserLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                city: nil,
                state: nil,
                country: nil
            )
        }
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            let locationError: LocationError
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    locationError = .permissionDenied
                case .locationUnknown:
                    locationError = .locationUnavailable
                default:
                    locationError = .unknown(error)
                }
            } else {
                locationError = .unknown(error)
            }
            
            self.error = locationError
            locationContinuation?.resume(throwing: locationError)
            locationContinuation = nil
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
}

