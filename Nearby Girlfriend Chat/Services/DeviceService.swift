//
//  DeviceService.swift
//  Nearby Girlfriend Chat
//

import UIKit

final class DeviceService {
    static let shared = DeviceService()
    
    private init() {}
    
    /// Returns the unique device identifier using identifierForVendor
    var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}

