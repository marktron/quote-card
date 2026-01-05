//
//  SettingsView.swift
//  QuoteCard
//
//  Settings window
//

import SwiftUI
import SafariServices

struct SettingsView: View {
    @AppStorage("defaultThemeId") private var defaultThemeId = "minimalist"
    @AppStorage("defaultAspectRatio") private var defaultAspectRatio = "portrait"

    @State private var extensionEnabled: Bool?

    var body: some View {
        Form {
            Section("Default Settings") {
                Picker("Theme:", selection: $defaultThemeId) {
                    ForEach(ThemeRegistry.shared.allThemes(), id: \.id) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }

                Picker("Aspect Ratio:", selection: $defaultAspectRatio) {
                    Text("Square (1:1)").tag("square")
                    Text("Portrait (4:5)").tag("portrait")
                    Text("Landscape (16:9)").tag("landscape")
                }
            }

            Section("About") {
                HStack {
                    Text("Version:")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Extension Status:")
                    Spacer()
                    if let enabled = extensionEnabled {
                        if enabled {
                            Text("Enabled")
                                .foregroundColor(.green)
                        } else {
                            Button("Enable in Safari") {
                                SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.markallen.QuoteCard.Extension")
                            }
                            .buttonStyle(.link)
                        }
                    } else {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }

                HStack {
                    Text("Support:")
                    Spacer()
                    Link("markallen.io/quotecard", destination: URL(string: "https://markallen.io/quotecard")!)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 250)
        .onAppear {
            checkExtensionState()
        }
    }

    private func checkExtensionState() {
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: "com.markallen.QuoteCard.Extension") { state, error in
            DispatchQueue.main.async {
                extensionEnabled = state?.isEnabled ?? false
            }
        }
    }
}

#Preview {
    SettingsView()
}
