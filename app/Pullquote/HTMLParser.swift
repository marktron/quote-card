//
//  HTMLParser.swift
//  Pullquote
//
//  Parses HTML content into AttributedString with theme styling
//

import Foundation
import AppKit
import SwiftUI

struct HTMLParser {
    let theme: Theme
    let baseFontSize: CGFloat

    func parse(html: String) -> AttributedString? {
        guard !html.isEmpty else { return nil }

        let modifiedHTML = preprocessHTML(html)
        let styledHTML = wrapWithStyles(modifiedHTML)

        guard let data = styledHTML.data(using: .utf8) else { return nil }

        return parseHTMLData(data)
    }

    private func preprocessHTML(_ html: String) -> String {
        var result = html

        // Add paragraph spacing by inserting <br><br> before </p> tags (except last)
        result = addSpacingBeforeTags(result, tag: "</p>", spacing: "<br><br>")

        // Add list item spacing with single <br> before </li> (except last)
        result = addSpacingBeforeTags(result, tag: "</li>", spacing: "<br>")

        return result
    }

    private func addSpacingBeforeTags(_ html: String, tag: String, spacing: String) -> String {
        var result = html
        var tagRanges: [Range<String.Index>] = []
        var searchStart = result.startIndex

        while let range = result.range(of: tag, range: searchStart..<result.endIndex) {
            tagRanges.append(range)
            searchStart = range.upperBound
        }

        // Insert spacing before each tag except the last one
        // Work backwards to preserve indices
        for i in stride(from: tagRanges.count - 2, through: 0, by: -1) {
            result.insert(contentsOf: spacing, at: tagRanges[i].lowerBound)
        }

        return result
    }

    private func wrapWithStyles(_ html: String) -> String {
        """
        <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display';
            font-size: \(baseFontSize)px;
            color: \(theme.text.color);
            font-weight: 500;
        }
        strong, b { font-weight: 600; }
        em, i { font-style: italic; }
        p { margin: 0; padding: 0; line-height: 1.4; }
        ul, ol { margin: 0; padding-left: 2.5em; margin-left: 0; line-height: 1.6; }
        li { margin: 0; padding: 0; padding-left: 0; line-height: 1.6; display: list-item; }
        </style>
        <body>\(html)</body>
        """
    }

    private func parseHTMLData(_ data: Data) -> AttributedString? {
        do {
            let nsAttributedString = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )

            let mutableAttrString = applyThemeFont(to: nsAttributedString)
            var attributedString = try AttributedString(mutableAttrString, including: \.appKit)

            // Apply theme text color
            if let nsColor = NSColor(hex: theme.text.color) {
                attributedString.foregroundColor = Color(nsColor)
            }

            return attributedString
        } catch {
            return nil
        }
    }

    private func applyThemeFont(to attributedString: NSAttributedString) -> NSMutableAttributedString {
        let mutableAttrString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableAttrString.length)

        let themeFontName = extractFontName(from: theme.fontFamily)

        mutableAttrString.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            guard let currentFont = value as? NSFont else { return }

            let traits = currentFont.fontDescriptor.symbolicTraits
            let newFont = createFont(
                baseName: themeFontName,
                size: baseFontSize,
                isBold: traits.contains(.bold),
                isItalic: traits.contains(.italic)
            )

            mutableAttrString.addAttribute(.font, value: newFont, range: range)
        }

        return mutableAttrString
    }

    private func extractFontName(from fontFamily: String) -> String {
        fontFamily.split(separator: ",")
            .first?
            .trimmingCharacters(in: .whitespaces) ?? "SFProDisplay"
    }

    private func createFont(baseName: String, size: CGFloat, isBold: Bool, isItalic: Bool) -> NSFont {
        if isBold && isItalic {
            if let font = NSFont(name: "\(baseName)-BoldItalic", size: size) {
                return font
            }
            if let font = NSFont(name: "\(baseName)-Bold", size: size) {
                return NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            }
        } else if isBold {
            if let font = NSFont(name: "\(baseName)-Bold", size: size) ??
                          NSFont(name: "\(baseName)-Semibold", size: size) {
                return font
            }
        } else if isItalic {
            if let font = NSFont(name: "\(baseName)-Italic", size: size) {
                return NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            }
        }

        return NSFont(name: baseName, size: size) ?? NSFont.systemFont(ofSize: size, weight: .medium)
    }
}
