//
//  Comms.swift
//  Web Scraper
//
//  Created by Darren Jones on 19/06/2024.
//

import Foundation

struct Comms {
    
    public func loadHTML(from url: URL) async throws -> String {
        
        let request = URLRequest(url: url, timeoutInterval: 30)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw CommsError.badStatusCode(code: (response as? HTTPURLResponse)?.statusCode) }
        
        guard let str = String(data: data, encoding: .utf8) else { throw CommsError.nilHTML }
        return str
    }
}
