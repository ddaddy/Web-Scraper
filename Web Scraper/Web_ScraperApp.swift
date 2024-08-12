//
//  Web_ScraperApp.swift
//  Web Scraper
//
//  Created by Darren Jones on 19/06/2024.
//

import SwiftUI

@main
struct Web_ScraperApp: App {
    
#if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
