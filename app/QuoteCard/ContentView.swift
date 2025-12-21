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

                        // Theme preview carousel
                        ThemeCarousel()

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
                    .background(
                        ZStack {
                            Color(NSColor.controlBackgroundColor)
                            // Subtle accent gradient overlay
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.accentColor.opacity(0.66), lineWidth: 3)
                    )
                } else {
                    VStack(spacing: 16) {
                        Spacer()

                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 24))
                            Text("All themes unlocked")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(spacing: 10) {
                            Text("Enjoying QuoteCard?")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Button {
                                    requestAppStoreReview()
                                } label: {
                                    Label("Rate", systemImage: "star.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)

                                ShareLink(item: URL(string: "https://apps.apple.com/app/quotecard/id6745029622")!) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        }
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

    private func requestAppStoreReview() {
        SKStoreReviewController.requestReview()
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

// MARK: - Theme Carousel

struct ThemeCarousel: View {
    @State private var offset: CGFloat = 0

    // Rich variety of theme colors from the premium collection
    private let themes: [(bg: String, text: String, isGradient: Bool, gradientEnd: String?)] = [
        ("#048DD6", "#FFFFFF", true, "#024A70"),   // Ocean gradient
        ("#9F0712", "#FFE2E2", false, nil),         // Cardinal
        ("#158545", "#DCFCE7", false, nil),         // Forest green
        ("#FFDF20", "#432004", true, "#F0B100"),   // Sunshine gradient
        ("#00D5BE", "#0F0D26", false, nil),         // Neon teal
        ("#7365C1", "#CBFBF1", false, nil),         // Pastel purple
        ("#646569", "#FFFFFF", false, nil),         // Concrete
        ("#110A12", "#FFFFFF", false, nil),         // Space dark
        ("#152602", "#9AE600", false, nil),         // Terminal
        ("#003327", "#FEF3C6", false, nil),         // Chalkboard
    ]

    private let tileSize: CGFloat = 38
    private let tileSpacing: CGFloat = 8
    private var tileUnit: CGFloat { tileSize + tileSpacing }

    var body: some View {
        GeometryReader { geometry in
            let visibleWidth = geometry.size.width
            let totalWidth = CGFloat(themes.count) * tileUnit

            HStack(spacing: tileSpacing) {
                // Triple the tiles for seamless looping
                ForEach(0..<3, id: \.self) { setIndex in
                    ForEach(Array(themes.enumerated()), id: \.offset) { index, theme in
                        ThemeTile(
                            bgColor: theme.bg,
                            textColor: theme.text,
                            isGradient: theme.isGradient,
                            gradientEnd: theme.gradientEnd,
                            size: tileSize
                        )
                        .id("\(setIndex)-\(index)")
                    }
                }
            }
            .offset(x: offset + visibleWidth / 2 - tileUnit / 2)
            .frame(width: visibleWidth, height: tileSize, alignment: .leading)
            .clipped()
            .mask(
                // Edge fade mask - sized to match container
                HStack(spacing: 0) {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 30)

                    Rectangle().fill(.black)

                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 30)
                }
                .frame(width: visibleWidth)
            )
            .onAppear {
                // Start from center set
                offset = -totalWidth
                startAnimation(totalWidth: totalWidth)
            }
        }
        .frame(height: tileSize)
        .clipped()
    }

    private func startAnimation(totalWidth: CGFloat) {
        // Continuous slow scroll animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            offset = -totalWidth * 2
        }
    }
}

struct ThemeTile: View {
    let bgColor: String
    let textColor: String
    let isGradient: Bool
    let gradientEnd: String?
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(backgroundFill)
            .frame(width: size, height: size)
            .overlay(
                Text("Aa")
                    .font(.system(size: size * 0.32, weight: .semibold))
                    .foregroundColor(Color(hex: textColor) ?? .white)
            )
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
    }

    private var backgroundFill: AnyShapeStyle {
        if isGradient, let endColor = gradientEnd {
            return AnyShapeStyle(LinearGradient(
                colors: [Color(hex: bgColor) ?? .gray, Color(hex: endColor) ?? .gray],
                startPoint: .top,
                endPoint: .bottom
            ))
        } else {
            return AnyShapeStyle(Color(hex: bgColor) ?? .gray)
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
