//
//  Previewer.swift
//  Web Scraper
//
//  Created by Darren Jones on 19/06/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct PreviewScreen: View {
    
    @State private var urlString: String = ""
    @State private var html: String = ""
    
    @State private var error: LocalizedAlertError? = nil
    
    var body: some View {
        VStack {
            HStack {
                TextField("URL", text: $urlString)
#if os(iOS)
                    .autocapitalization(.none)
#endif
                    .onSubmit {
                        // When pressing the enter key
                        Task {
                            await previewURL(urlString)
                        }
                    }
                
                Button {
                    urlString = ""
                    html = ""
                } label: {
                    Image(systemName: "clear")
                }
                
                Button {
                    Task {
                        await previewURL(urlString)
                    }
                } label: {
                    Image(systemName: "play")
                }
            }
            
            HStack {
                Spacer()
                PasteButton(supportedContentTypes: [UTType.text, UTType.url, UTType.rtf], payloadAction: pasted(items:))
                    .tint(.blue)
                Spacer()
            }
            
            ScrollView([.vertical]) {
                VStack(alignment: .leading) {
                    Text(html)
                        .lineLimit(nil)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .alert(isPresented: .constant(error != nil), error: error, actions: { _ in
            Button("Dismiss") {
                error = nil
            }
        }, message: { error in
            Text(error.recoverySuggestion ?? "")
        })
    }
    
    private func previewURL(_ urlString: String) async {
        html = ""
        
        guard let url = URL(string: urlString) else {
            self.error = LocalizedAlertError(error: CommsError.invalidURL)
            return
        }
        
        do {
            html = try await Comms().loadHTML(from: url)
        } catch {
            self.error = LocalizedAlertError(error: error)
        }
    }
    
}

// MARK: - Pasteboard
extension PreviewScreen {
    
    private func pasted(items: [NSItemProvider]) {
        Task {
            await pasted(items: items)
        }
    }
    
    private func pasted(items: [NSItemProvider]) async {
        
        for item in items {
            if item.canLoadObject(ofClass: String.self) {
                let _ = item.loadObject(ofClass: String.self) { item, error in
                    if let string = item {
                        Task {
                            await pastedText(string)
                        }
                    }
                }
            } else if item.canLoadObject(ofClass: URL.self) {
                let _ = item.loadObject(ofClass: URL.self) { item, error in
                    if let url = item {
                        Task {
                            await pastedText(url.absoluteString)
                        }
                    }
                }
            } else if item.hasItemConformingToTypeIdentifier(UTType.rtf.identifier) {
                let data = try? await item.loadItem(forTypeIdentifier: UTType.rtf.identifier)
                if let data = data as? Data,
                   let attributedString = try? NSAttributedString(data: data, documentAttributes: nil) {
                    await pastedText(attributedString.string)
                }
            }
        }
    }
    
    private func pastedText(_ string: String?) async {
        guard let string else { return }
        
        urlString = string
        await previewURL(urlString)
    }
}

#Preview {
    PreviewScreen()
}
