//
//  Error.swift
//  Web Scraper
//
//  Created by Darren Jones on 19/06/2024.
//

import Foundation

enum CommsError: Error, LocalizedError {
    case invalidURL
    case invalidStatus(status: ProcessItem.Status)
    case nilHTML
    case badStatusCode(code: Int?)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidStatus(let status):
            return "Invalid status: \(status)"
        case .nilHTML:
            return "HTML is nil"
        case .badStatusCode(let code):
            return "Received StatusCode: \(String(describing: code))"
        }
    }
}

struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError
    
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }
    
    init?(error: Error? ) {
        guard let localizedError = error as? LocalizedError else { return nil }
        underlyingError = localizedError
    }
}
