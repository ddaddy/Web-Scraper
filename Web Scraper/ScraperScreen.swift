//
//  ScraperScreen.swift
//  Web Scraper
//
//  Created by Darren Jones on 19/06/2024.
//

import SwiftUI
import XlsxReaderWriter

struct ScraperScreen: View {
    
    @State private var worksheet: BRAWorksheet?
    
    @State private var scanString: String = ""
    @State private var column: String = ""
    @State private var items: [ProcessItem] = []
    @State private var finished: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Clear", systemImage: "clear") {
                    clear()
                }
            }
            
            HStack {
                TextField("URL Column", text: $column)
                    .frame(width: 100)
                
                TextField("String to find", text: $scanString)
                    .padding()
            }
            
            if items.isEmpty && !column.isEmpty {
                FileDropView(column: column, worksheet: $worksheet, items: $items)
            } else {
                ZStack {
                    FileDropView(column: column, worksheet: $worksheet, items: $items)
                        .hidden()
                    
                    List(items, id: \.cell.reference) { item in
                        HStack {
                            item.status.image
                                .frame(width: 20, height: 20)
                            Text("\(item.cell.reference)")
                            Text("\(item.url)")
                            if case let .error(error) = item.status {
                                Text(error.localizedDescription)
                            }
                        }
                    }
                }
            }
            
            if !items.isEmpty && !scanString.isEmpty && !finished {
                Button("Start Scraping") {
                    Task {
                        await startScraping()
                    }
                }
            } else if finished {
                Button("Save Results") {
                    Task {
                        await saveResults()
                    }
                }
            }
        }
        .padding()
    }
}

private extension ScraperScreen {
    
    private func clear() {
        worksheet = nil
        items = []
        scanString = ""
        column = ""
        finished = false
    }
    
    private func startScraping() async {
        
        finished = false
        
        await withTaskGroup(of: Void.self) { group in
            for item in items {
                group.addTask {
                    try? await item.scanHtml(for: scanString)
                }
            }
        }
        
        self.finished = true
    }
    
    @MainActor
    private func saveResults() async {
        guard let csv = resultsCSV(),
              let url = showSavePanel() else { return }
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            print("Success")
        } catch {
            
        }
    }
    
    @MainActor
    private func resultsCSV() -> String? {
        guard let maxRow = items.map({ $0.cell.rowIndex() }).max() else { return nil }
        
        var results = ""
        for row in 1...maxRow {
            if let item = items.first(where: { $0.cell.rowIndex() == row }) {
                results += "\(item.cell.rowIndex()),\(item.url),\(item.status.successString)\n"
            } else {
                results += "\(row)\n"
            }
        }
        return results
    }
    
    @MainActor
    private func showSavePanel() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save results as csv"
        savePanel.message = "Choose a folder and a name to store the results."
        savePanel.nameFieldLabel = "CSV file name:"
        savePanel.nameFieldStringValue = "results.csv"
        
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }
}

// MARK: - URL Validation
extension String {

    var isValidURL: Bool {
        guard !isEmpty, !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: self,
                                           options: [],
                                           range: NSRange(location: .zero, length: utf16.count))
            return !matches.isEmpty
        } catch {
            return false
        }
    }
}

#Preview {
    ScraperScreen()
}
