//
//  RenderTypes.swift
//  QuoteCard
//
//  Shared types for rendering quote cards
//  These match the TypeScript types in extension/src/shared/types.ts
//

import Foundation

enum AspectRatio: String, Codable {
    case square
    case portrait
    case landscape
}

enum ExportFormat: String, Codable {
    case png
    case jpeg
}

struct RenderSettings: Codable {
    let themeId: String
    let aspectRatio: AspectRatio
    let exportFormat: ExportFormat
    let includeAttribution: Bool

    static var `default`: RenderSettings {
        RenderSettings(
            themeId: "scholarly",
            aspectRatio: .portrait,
            exportFormat: .png,
            includeAttribution: true
        )
    }
}

struct RenderRequest: Codable {
    let id: String
    let text: String
    let html: String?
    let sourceTitle: String?
    let sourceUrl: String?
    let faviconUrl: String?
    let createdAt: Int64
    let settingsOverride: RenderSettings?
}

struct RenderResult: Codable {
    let id: String
    let success: Bool
    let errorMessage: String?
    let dataUrl: String?
}

// MARK: - Theme Models

struct Theme: Codable {
    let id: String
    let name: String
    let fontFamily: String
    let fontWeight: Int
    let background: Background
    let text: TextStyle
    let padding: CGFloat
    let footer: Footer?

    struct Background: Codable {
        let type: String?
        let color: String?
        let gradient: Gradient?
        let image: ImageBackground?

        struct Gradient: Codable {
            let colors: [String]
            let direction: String?
        }

        struct ImageBackground: Codable {
            let url: String
            let overlay: String?
        }
    }

    struct TextStyle: Codable {
        let size: CGFloat
        let color: String
        let lineHeight: CGFloat
        let maxWidth: String
        let glow: Glow?

        struct Glow: Codable {
            let color: String
            let radius: CGFloat
            let opacity: CGFloat
        }
    }

    struct Footer: Codable {
        let enabled: Bool
        let color: String
        let opacity: CGFloat
    }
}
