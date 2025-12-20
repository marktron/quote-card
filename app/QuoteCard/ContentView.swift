//
//  ContentView.swift
//  QuoteCard
//
//  Main window content
//

import SwiftUI
import SafariServices
import StoreKit

struct ContentView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showingPurchaseError = false
    @State private var purchaseError = ""

    private let themePreviewColors: [(bg: String, text: String)] = [
        ("#048DD6", "#FFFFFF"),  // Ocean - white text
        ("#9F0712", "#FFFFFF"),  // Cardinal - white text
        ("#158545", "#FFFFFF"),  // Forest - white text
        ("#FFDF20", "#806F00"),  // Sunshine - dark yellow text
        ("#00D5BE", "#00665B")   // Neon/Teal - dark teal text
    ]

    private var paidThemeCount: Int {
        // Try to load from extension bundle's shared folder
        if let extensionURL = Bundle.main.builtInPlugInsURL?
            .appendingPathComponent("QuoteCard Extension.appex"),
           let extensionBundle = Bundle(url: extensionURL),
           let themesURL = extensionBundle.url(forResource: "themes", withExtension: "json", subdirectory: "shared"),
           let data = try? Data(contentsOf: themesURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let themes = json["themes"] as? [[String: Any]] {
            return themes.filter { ($0["free"] as? Bool) != true }.count
        }
        // Fallback: count from themes.json structure (15 paid themes as of current version)
        return 15
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image("LogoIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)

                    Text("appName", tableName: "Localizable")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .offset(y: -4)
                }

                Text("appTagline", tableName: "Localizable")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 28)

            // Two-column layout
            HStack(spacing: 16) {
                // Left column: Setup
                VStack(alignment: .leading, spacing: 18) {
                    Text("Get Started")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 12) {
                        SetupStepRow(number: "1", text: String(localized: "step1", table: "Localizable"))
                        SetupStepRow(number: "2", text: String(localized: "step2", table: "Localizable"))
                        SetupStepRow(number: "3", text: String(localized: "step3", table: "Localizable"))
                    }

                    Spacer()

                    Button {
                        SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.markallen.QuoteCard.Extension") { _ in }
                    } label: {
                        Text(String(localized: "openSafariExtensions", table: "Localizable"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Right column: Upgrade
                if !purchaseManager.allThemesUnlocked {
                    VStack(spacing: 18) {
                        Text("Unlock All Themes")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .frame(maxWidth: .infinity)

                        // Theme preview strip
                        HStack(spacing: 6) {
                            ForEach(Array(themePreviewColors.enumerated()), id: \.offset) { _, colors in
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color(hex: colors.bg) ?? .gray)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Text("Aa")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(Color(hex: colors.text) ?? .white)
                                    )
                            }
                        }

                        Text("Get \(paidThemeCount) additional themes including gradients, textures, and unique styles.")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        if let product = purchaseManager.allThemesProduct {
                            Button {
                                Task { await purchase() }
                            } label: {
                                if purchaseManager.purchaseInProgress {
                                    ProgressView()
                                        .controlSize(.small)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("Unlock for \(product.displayPrice)")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(purchaseManager.purchaseInProgress)
                        } else {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Button("Restore Purchases") {
                            Task { await restorePurchases() }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                        .disabled(purchaseManager.purchaseInProgress)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 24))
                        Text("All themes unlocked")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Text("noAppNeeded", tableName: "Localizable")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.top, 12)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Purchase Error", isPresented: $showingPurchaseError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseError)
        }
    }

    private func purchase() async {
        do {
            try await purchaseManager.purchase()
        } catch {
            if case PurchaseError.userCancelled = error {
                return
            }
            purchaseError = error.localizedDescription
            showingPurchaseError = true
        }
    }

    private func restorePurchases() async {
        do {
            try await purchaseManager.restorePurchases()
        } catch {
            purchaseError = error.localizedDescription
            showingPurchaseError = true
        }
    }
}

struct SetupStepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ContentView()
}
