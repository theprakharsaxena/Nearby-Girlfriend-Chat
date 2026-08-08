//
//  GenerationStatus.swift
//  Nearby Girlfriend Chat
//

import Foundation

enum GenerationStatus: String, Codable {
    case pending
    case inProgress = "in_progress"
    case completed
    case failed
    case notFound = "not_found"
    
    var displayText: String {
        switch self {
        case .pending:
            return "Waiting to start..."
        case .inProgress:
            return "Finding matches nearby..."
        case .completed:
            return "All matches found!"
        case .failed:
            return "Something went wrong"
        case .notFound:
            return "No matches yet"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .pending, .inProgress:
            return true
        case .completed, .failed, .notFound:
            return false
        }
    }
}

