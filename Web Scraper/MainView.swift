//
//  MainView.swift
//  Web Scraper
//
//  Created by Darren Jones on 19/06/2024.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            ScraperScreen()
                .tabItem {
                    Label("Scraper", systemImage: "binoculars")
                }

            PreviewScreen()
                .tabItem {
                    Label("HTML Preview", systemImage: "magnifyingglass")
                }
        }
    }
}

#Preview {
    MainView()
}
