//
//  QuoteCardApp.swift
//  QuoteCard
//
//  Main app entry point
//

import SwiftUI

@main
struct QuoteCardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("", id: "main") {
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

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle quotecard:// URL scheme
        // The app will just come to the foreground - purchase UI is on main screen
        for url in urls {
            if url.scheme == "quotecard" {
                // Bring app to front
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Don't open new windows when app is reopened
        return true
    }
}
