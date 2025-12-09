//
//  ThemeRegistry.swift
//  QuoteCard
//
//  Manages loading and accessing themes
//

import Foundation
import AppKit

class ThemeRegistry {
    static let shared = ThemeRegistry()

    private var themes: [String: Theme] = [:]

    private init() {
        loadThemes()
    }

    func theme(withId id: String) -> Theme? {
        print("ThemeRegistry: Looking up theme with ID: '\(id)'")
        let theme = themes[id]
        if theme == nil {
            print("ThemeRegistry: Theme '\(id)' NOT FOUND. Available themes: \(themes.keys.sorted())")
        } else {
            print("ThemeRegistry: Found theme '\(theme!.name)'")
        }
        return theme
    }

    func allThemes() -> [Theme] {
        return Array(themes.values)
    }

    private func loadThemes() {
        // Load themes from shared JSON file
        guard let url = Bundle.main.url(forResource: "themes", withExtension: "json", subdirectory: "shared"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let themesArray = json["themes"] as? [[String: Any]] else {
            print("Failed to load themes.json, using fallback")
            loadFallbackTheme()
            return
        }

        for themeData in themesArray {
            guard let id = themeData["id"] as? String,
                  let name = themeData["name"] as? String,
                  let fontData = themeData["font"] as? [String: Any],
                  let fontFamily = fontData["family"] as? String,
                  let backgroundData = themeData["background"] as? [String: Any],
                  let textData = themeData["text"] as? [String: Any],
                  let textColor = textData["color"] as? String,
                  let fontSize = textData["fontSize"] as? Int,
                  let lineHeight = textData["lineHeight"] as? Double,
                  let footerData = themeData["footer"] as? [String: Any],
                  let footerEnabled = footerData["enabled"] as? Bool,
                  let footerColor = footerData["color"] as? String,
                  let footerOpacity = footerData["opacity"] as? Double,
                  let layoutData = themeData["layout"] as? [String: Any],
                  let padding = layoutData["padding"] as? Int else {
                continue
            }

            // Parse background (solid color, gradient, or image)
            let background: Theme.Background
            let backgroundType = backgroundData["type"] as? String
            let backgroundColor = backgroundData["color"] as? String

            if backgroundType == "image",
               let imageData = backgroundData["image"] as? [String: Any],
               let imageUrl = imageData["url"] as? String {
                let overlay = imageData["overlay"] as? String
                background = Theme.Background(
                    type: "image",
                    color: backgroundColor,
                    gradient: nil,
                    image: Theme.Background.ImageBackground(url: imageUrl, overlay: overlay)
                )
            } else if let gradientData = backgroundData["gradient"] as? [String: Any],
               let colors = gradientData["colors"] as? [String] {
                let direction = gradientData["direction"] as? String
                background = Theme.Background(
                    type: "gradient",
                    color: backgroundColor,
                    gradient: Theme.Background.Gradient(colors: colors, direction: direction),
                    image: nil
                )
            } else if let bgColor = backgroundColor {
                background = Theme.Background(type: "solid", color: bgColor, gradient: nil, image: nil)
            } else {
                continue
            }

            // Parse optional glow effect
            var glow: Theme.TextStyle.Glow? = nil
            if let glowData = textData["glow"] as? [String: Any],
               let glowColor = glowData["color"] as? String,
               let glowRadius = glowData["radius"] as? Double,
               let glowOpacity = glowData["opacity"] as? Double {
                glow = Theme.TextStyle.Glow(
                    color: glowColor,
                    radius: CGFloat(glowRadius),
                    opacity: CGFloat(glowOpacity)
                )
            }

            let theme = Theme(
                id: id,
                name: name,
                fontFamily: fontFamily,
                background: background,
                text: Theme.TextStyle(
                    size: CGFloat(fontSize),
                    color: textColor,
                    lineHeight: lineHeight,
                    maxWidth: "80%",
                    glow: glow
                ),
                padding: CGFloat(padding),
                footer: Theme.Footer(
                    enabled: footerEnabled,
                    color: footerColor,
                    opacity: footerOpacity
                )
            )

            themes[id] = theme
        }
    }

    private func loadFallbackTheme() {
        // Fallback to Soft Sand if JSON loading fails
        let softSand = Theme(
            id: "soft-sand",
            name: "Soft Sand",
            fontFamily: "Inter",
            background: Theme.Background(type: "solid", color: "#F7F1E8", gradient: nil, image: nil),
            text: Theme.TextStyle(size: 40, color: "#171615", lineHeight: 1.35, maxWidth: "80%", glow: nil),
            padding: 64,
            footer: Theme.Footer(enabled: true, color: "#6F6254", opacity: 0.75)
        )
        themes["soft-sand"] = softSand
    }

    private func loadThemeFromFile(_ filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil),
              let data = try? Data(contentsOf: url),
              let theme = try? JSONDecoder().decode(Theme.self, from: data) else {
            print("Failed to load theme from \(filename)")
            return
        }

        themes[theme.id] = theme
    }
}

// MARK: - Color Extensions

extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
