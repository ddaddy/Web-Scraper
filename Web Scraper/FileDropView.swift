//
//  FileDropView.swift
//  Web Scraper
//
//  Created by Darren Jones on 20/06/2024.
//

import SwiftUI
import XlsxReaderWriter

struct FileDropView: View {
    
    @State private var dropping: Bool = false
    let column: String
    @Binding var worksheet: BRAWorksheet?
    @Binding var items: [ProcessItem]
    
    var body: some View {
        ZStack {
            Image(systemName: "doc.plaintext")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 100)
                .foregroundColor(dropping ? .blue : .gray)
                .padding()
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 4, dash: [10]))
                .foregroundColor(dropping ? .blue : .gray)
                .dropDestination(for: Data.self) { items, location in
                    guard let item = items.first else { return false }
                    guard let _ = try? processFile(item) else { return false }
                    return true
                } isTargeted: { status in
                    dropping = status
                }
        }
        .padding()
    }
}

// MARK: - Spreadsheet/File
private extension FileDropView {
    
    private func processFile(_ data: Data) throws -> Bool {
        
        let url = URL.temporaryDirectory.appending(path: "temp.xlsx", directoryHint: .notDirectory)
        do {
            // Save the file to temp
            try data.write(to: url, options: [.atomic])
            Task {
                // We will be async from here
                guard let worksheet = await loadSpreadsheet(url) else { return }
                self.worksheet = worksheet
                // Get the cells to read
                items = await fetchCellsInColumn(column.uppercased(), from: worksheet)
            }
            return true
        } catch {
            return false
        }
    }
    
    private func loadSpreadsheet(_ url: URL) async -> BRAWorksheet? {
        
        // Open it as a spreadsheet
        let spreadsheet = BRAOfficeDocumentPackage.open(url.path())
        // Make sure we have a workbook
        guard let workbook = spreadsheet?.workbook,
              let worksheets = workbook.worksheets,
              worksheets.count > 0,
              let firstWorksheet = workbook.worksheets[0] as? BRAWorksheet else { return nil }
        
        return firstWorksheet
    }
    
    @MainActor
    private func fetchCellsInColumn(_ column: String, from worksheet: BRAWorksheet) async -> [ProcessItem] {
        guard let cells = worksheet.cells as? [BRACell] else { return [] }
        let filtered = cells.filter({ $0.columnName() == column })
        return filtered.compactMap({ ProcessItem(cell: $0) })
    }
}
