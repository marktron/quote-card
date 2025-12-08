//
//  ColorUtils.swift
//  Pullquote
//
//  Color parsing utilities for themes
//

import Foundation
import SwiftUI
import AppKit

struct ColorUtils {
    static func parseRGBA(_ rgba: String) -> Color? {
        let pattern = #"rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: rgba, range: NSRange(rgba.startIndex..., in: rgba)) else {
            return nil
        }

        func extractInt(_ index: Int) -> Int? {
            guard let range = Range(match.range(at: index), in: rgba) else { return nil }
            return Int(rgba[range])
        }

        func extractDouble(_ index: Int) -> Double? {
            guard let range = Range(match.range(at: index), in: rgba) else { return nil }
            return Double(rgba[range])
        }

        guard let r = extractInt(1), let g = extractInt(2), let b = extractInt(3) else {
            return nil
        }
        let a = extractDouble(4) ?? 1.0

        return Color(
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: a
        )
    }

    static func parseGradientColors(_ hexColors: [String]) -> [Color]? {
        let colors = hexColors.compactMap { hex -> Color? in
            guard let nsColor = NSColor(hex: hex) else { return nil }
            return Color(nsColor)
        }
        return colors.isEmpty ? nil : colors
    }

    static func color(fromHex hex: String?, default defaultColor: NSColor = .black) -> Color {
        guard let hex = hex, let nsColor = NSColor(hex: hex) else {
            return Color(defaultColor)
        }
        return Color(nsColor)
    }
}
