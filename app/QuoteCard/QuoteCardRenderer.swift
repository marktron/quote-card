//
//  QuoteCardRenderer.swift
//  QuoteCard
//
//  Renders quote cards to images
//

import Foundation
import SwiftUI
import AppKit

class QuoteCardRenderer {
    static let shared = QuoteCardRenderer()

    private init() {}

    func render(request: RenderRequest) async -> RenderResult {
        let settings = request.settingsOverride ?? RenderSettings.default

        guard let theme = ThemeRegistry.shared.theme(withId: settings.themeId) else {
            return RenderResult(
                id: request.id,
                success: false,
                errorMessage: "Theme '\(settings.themeId)' not found",
                dataUrl: nil
            )
        }

        do {
            let scale: CGFloat = 1.0
            let size = canvasSize(for: settings.aspectRatio, scale: scale)
            let faviconImage = loadFavicon(from: request.faviconUrl)

            let view = QuoteCardView(
                text: request.text,
                html: request.html,
                sourceTitle: settings.includeAttribution ? request.sourceTitle : nil,
                sourceUrl: settings.includeAttribution ? request.sourceUrl : nil,
                faviconImage: faviconImage,
                theme: theme,
                scale: scale
            )

            let image = try await renderSwiftUIView(view, size: size)

            guard let imageData = imageData(from: image, format: settings.exportFormat) else {
                return RenderResult(
                    id: request.id,
                    success: false,
                    errorMessage: "Failed to encode image",
                    dataUrl: nil
                )
            }

            let base64 = imageData.base64EncodedString()
            let mimeType = settings.exportFormat == .jpeg ? "image/jpeg" : "image/png"
            let dataUrl = "data:\(mimeType);base64,\(base64)"

            return RenderResult(
                id: request.id,
                success: true,
                errorMessage: nil,
                dataUrl: dataUrl
            )

        } catch {
            return RenderResult(
                id: request.id,
                success: false,
                errorMessage: "Rendering failed: \(error.localizedDescription)",
                dataUrl: nil
            )
        }
    }

    private func loadFavicon(from dataUrl: String?) -> NSImage? {
        guard let faviconDataUrl = dataUrl, faviconDataUrl.hasPrefix("data:") else {
            return nil
        }

        let parts = faviconDataUrl.split(separator: ",", maxSplits: 1)
        guard parts.count == 2,
              let imageData = Data(base64Encoded: String(parts[1])),
              let image = NSImage(data: imageData) else {
            return nil
        }
        return image
    }

    private func canvasSize(for aspectRatio: AspectRatio, scale: CGFloat = 2.0) -> CGSize {
        switch aspectRatio {
        case .square:
            return CGSize(width: 1080 * scale, height: 1080 * scale)
        case .portrait:
            return CGSize(width: 1080 * scale, height: 1350 * scale)
        case .landscape:
            return CGSize(width: 1920 * scale, height: 1080 * scale)
        }
    }

    private func renderSwiftUIView<V: View>(_ view: V, size: CGSize) async throws -> NSImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let hostingView = NSHostingView(rootView: view)
                hostingView.frame = CGRect(origin: .zero, size: size)

                guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
                    continuation.resume(throwing: NSError(
                        domain: "QuoteCardRenderer",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap representation"]
                    ))
                    return
                }

                hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)

                let image = NSImage(size: size)
                image.addRepresentation(bitmapRep)

                continuation.resume(returning: image)
            }
        }
    }

    private func imageData(from image: NSImage, format: ExportFormat) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)

        switch format {
        case .png:
            return bitmapRep.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.80])
        }
    }
}

// MARK: - Quote Card View

struct QuoteCardView: View {
    let text: String
    let html: String?
    let sourceTitle: String?
    let sourceUrl: String?
    let faviconImage: NSImage?
    let theme: Theme
    let scale: CGFloat

    private var baseFontSize: CGFloat {
        160 * scale
    }

    private var textColor: Color {
        ColorUtils.color(fromHex: theme.text.color, default: .black)
    }

    private var footerColor: Color {
        ColorUtils.color(fromHex: theme.footer?.color ?? "#666666", default: .gray)
    }

    var body: some View {
        ZStack {
            backgroundView

            VStack(alignment: .leading, spacing: 32 * scale) {
                quoteTextView
                Spacer()
                footerView
            }
            .padding(theme.padding * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private var quoteTextView: some View {
        let parser = HTMLParser(theme: theme, baseFontSize: baseFontSize)
        if let attributedText = parser.parse(html: html ?? "") {
            Text(attributedText)
                .minimumScaleFactor(0.2)
                .lineLimit(nil)
                .lineSpacing(16 * scale)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .allowsTightening(true)
                .modifier(GlowModifier(glow: theme.text.glow, scale: scale))
        } else {
            Text(text)
                .font(customFont(size: baseFontSize))
                .fontWeight(themeFontWeight)
                .foregroundColor(textColor)
                .minimumScaleFactor(0.2)
                .lineLimit(nil)
                .lineSpacing(16 * scale)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .allowsTightening(true)
                .modifier(GlowModifier(glow: theme.text.glow, scale: scale))
        }
    }

    @ViewBuilder
    private var footerView: some View {
        if let title = sourceTitle, theme.footer?.enabled == true {
            let footerFontSize: CGFloat = 42 * scale
            let iconSize = footerFontSize * 1.2

            HStack(alignment: .center, spacing: footerFontSize * 0.4) {
                if let favicon = faviconImage {
                    Image(nsImage: favicon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                }

                Text(title)
                    .font(customFont(size: footerFontSize))
                    .fontWeight(themeFontWeight)
                    .foregroundColor(footerColor)
                    .opacity(Double(theme.footer?.opacity ?? 0.7))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if theme.background.type == "image", let imageConfig = theme.background.image {
            imageBackgroundView(imageConfig)
        } else if let gradient = theme.background.gradient,
                  let colors = ColorUtils.parseGradientColors(gradient.colors) {
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: gradient.direction == "horizontal" ? .leading : .top,
                endPoint: gradient.direction == "horizontal" ? .trailing : .bottom
            )
        } else if let colorHex = theme.background.color {
            ColorUtils.color(fromHex: colorHex, default: .white)
        } else {
            Color.white
        }
    }

    @ViewBuilder
    private func imageBackgroundView(_ imageConfig: Theme.Background.ImageBackground) -> some View {
        GeometryReader { geometry in
            ZStack {
                if let nsImage = loadBackgroundImage(named: imageConfig.url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else if let colorHex = theme.background.color {
                    ColorUtils.color(fromHex: colorHex, default: .white)
                }

                if let overlayColor = imageConfig.overlay,
                   let color = ColorUtils.parseRGBA(overlayColor) {
                    color
                }
            }
        }
    }

    private func loadBackgroundImage(named filename: String) -> NSImage? {
        let baseName = filename.replacingOccurrences(of: ".jpg", with: "")

        // Try extension bundle first
        if let url = Bundle(identifier: "com.markallen.QuoteCard.Extension")?
            .url(forResource: baseName, withExtension: "jpg") {
            return NSImage(contentsOf: url)
        }

        // Fallback to main bundle
        if let url = Bundle.main.url(forResource: baseName, withExtension: "jpg") {
            return NSImage(contentsOf: url)
        }

        return nil
    }

    private func customFont(size: CGFloat) -> Font {
        let fontName = theme.fontFamily.split(separator: ",")
            .first?
            .trimmingCharacters(in: .whitespaces) ?? "SFProDisplay"
        return .custom(String(fontName), size: size)
    }

    private var themeFontWeight: Font.Weight {
        switch theme.fontWeight {
        case ...199: return .ultraLight
        case 200...299: return .thin
        case 300...399: return .light
        case 400...499: return .regular
        case 500...599: return .medium
        case 600...699: return .semibold
        case 700...799: return .bold
        case 800...899: return .heavy
        default: return .black
        }
    }
}

// MARK: - Glow Effect Modifier

struct GlowModifier: ViewModifier {
    let glow: Theme.TextStyle.Glow?
    let scale: CGFloat

    func body(content: Content) -> some View {
        if let glow = glow {
            content
                .shadow(
                    color: ColorUtils.color(fromHex: glow.color, default: .clear)
                        .opacity(glow.opacity),
                    radius: glow.radius * scale,
                    x: 0,
                    y: 0
                )
        } else {
            content
        }
    }
}
