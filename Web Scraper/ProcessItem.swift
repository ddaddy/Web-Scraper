//
//  ProcessItem.swift
//  Web Scraper
//
//  Created by Darren Jones on 20/06/2024.
//

import Foundation
@preconcurrency import XlsxReaderWriter
import SwiftUI

@MainActor
@Observable
class ProcessItem: Sendable, Identifiable {
    
    indirect enum Status {
        case none
        case valid
        case loading
        case loaded
        case scraping
        case found
        case notFound
        case error(error: any Error)
        
        @ViewBuilder
        var image: some View {
            switch self {
            case .none:
                EmptyView()
            case .valid:
                Image(systemName: "link")
                    .resizable()
            case .loading:
                ProgressView()
                    .controlSize(.small)
            case .loaded:
                EmptyView()
            case .scraping:
                EmptyView()
            case .found:
                Image(systemName: "checkmark")
                    .resizable()
                    .background(.green)
            case .notFound:
                Image(systemName: "xmark")
                    .resizable()
                    .background(.red)
            case .error:
                Image(systemName: "exclamationmark.circle.fill")
                    .resizable()
                    .foregroundColor(.red)
            }
        }
        
        var successString: String {
            switch self {
            case .none:
                ""
            case .valid:
                ""
            case .loading:
                ""
            case .loaded:
                ""
            case .scraping:
                ""
            case .found:
                "MATCH"
            case .notFound:
                "NO MATCH"
            case .error(let error):
                "ERROR: \(error.localizedDescription)"
            }
        }
    }
    
    let cell: BRACell
    let url: URL
    var status: Status = .none
    
    init?(cell: BRACell) {
        self.cell = cell
        
        guard let url = Self.fetchURL(from: cell) else { return nil }
        self.url = url
        self.status = .valid
    }
    
    private static func fetchURL(from cell: BRACell) -> URL? {
        guard var string = cell.stringValue(),
              string.isValidURL else { return nil }
        
        if !string.hasPrefix("http") {
            string = "https://" + string
        }
        return URL(string: string)
    }
    
    public func scanHtml(for string: String) async throws {
        
        guard case .valid = status else { throw CommsError.invalidStatus(status: status) }
        do {
            let html = try await loadHTML()
            
            if let _ = html.range(of: string, options: .caseInsensitive) {
                print("✅", self, url)
                status = .found
            } else {
                print("⛔️", self, url, html.count)
                status = .notFound
            }
        } catch {
            status = .error(error: error)
        }
    }
    
    public func loadHTML() async throws -> String {
        guard case .valid = status else { throw CommsError.invalidStatus(status: status) }
        
        status = .loading
        let html = try await Comms().loadHTML(from: url)
        status = .loaded
        return html
    }
}
