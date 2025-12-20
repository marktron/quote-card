//
//  SettingsView.swift
//  QuoteCard
//
//  Settings window
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultThemeId") private var defaultThemeId = "minimalist"
    @AppStorage("defaultAspectRatio") private var defaultAspectRatio = "portrait"
    @AppStorage("defaultExportFormat") private var defaultExportFormat = "png"
    @AppStorage("includeAttribution") private var includeAttribution = true

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

                Picker("Export Format:", selection: $defaultExportFormat) {
                    Text("PNG").tag("png")
                    Text("JPEG").tag("jpeg")
                }

                Toggle("Include Attribution", isOn: $includeAttribution)
                    .help("Show source title at the bottom of quote cards")
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
                    Button("Open Safari Preferences") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Safari-Settings-Extensions")!)
                    }
                    .buttonStyle(.link)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 250)
    }
}

#Preview {
    SettingsView()
}
