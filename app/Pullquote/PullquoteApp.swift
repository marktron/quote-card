//
//  PullquoteApp.swift
//  Pullquote
//
//  Main app entry point
//

import SwiftUI

@main
struct PullquoteApp: App {
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
