//
//  QuoteCardApp.swift
//  QuoteCard
//
//  Main app entry point
//

import SwiftUI

@main
struct QuoteCardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
        }
    }
}
