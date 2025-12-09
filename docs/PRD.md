# PRD: QuoteCard Safari Extension

QuoteCard is a premium Safari extension for generating beautiful, shareable quote images from selected webpage text.

---

## 1. Product Summary

A macOS Safari extension that lets users highlight text → generate a beautifully styled image card suitable for Instagram, Twitter, and newsletters. The tool focuses on:

- High-quality curated themes
- Instant, low-friction interaction
- A polished, Apple-grade user experience
- Output that enhances personal branding and editorial workflows

Support for a future Chrome WebExtension port is required at the architecture level.

The product occupies a niche currently underserved: users want to capture and share text excerpts the same way they share photos or screenshots — but with aesthetic consistency and zero friction.

---

## 2. Target Users

### Primary

- Writers, creators, and knowledge workers
- Instagram/Twitter users who share insights
- Readers who annotate blogs, Substack, essays
- Designers who care about typography and visual polish

### Secondary

- Educators
- Marketers
- Entrepreneurs promoting content

These users want speed + consistency, and dislike manually building quote cards in Canva or image editors.

---

## 3. User Goals

1. Highlight text on a page and instantly convert it to a card.
2. Choose from elegant presets (themes).
3. Export with a single click to:
   - PNG
   - JPEG
   - Clipboard
   - Direct share (macOS share sheet)
4. Maintain consistent style across posts.
5. Generate cards quickly enough that it becomes a habit.

---

## 4. Non-Goals

- No editing of the original webpage.
- No full image editing suite.
- No cross-device sync in V1 (themes are local).
- No mobile Safari support in V1 (iOS extension constraints).

---

## 5. Value Proposition

### Differentiation

- First Safari-native extension focused on quote card creation, not screenshots or annotation.
- Apple-quality typography and themes out of the box.
- Speed: one gesture from highlight to export.
- Controlled, consistent aesthetic (unlike Canva templates which look generic).

### Pricing Model

- Premium app (one-time purchase)
- Optional: theme pack expansions as in-app purchases
- Optional: Pro unlock (custom fonts + brand colors)

---

## 6. Core Use Cases

### UC1 — Create a shareable image from highlighted text

1. User highlights text.
2. Right-click → "Create QuoteCard" OR toolbar click.
3. A small modal opens with a preview.
4. User selects theme → export.

### UC2 — Quick export without modal (power-user mode)

1. User highlights text.
2. Uses keyboard shortcut (e.g. ⇧⌘Q).
3. Image auto-generated and copied to clipboard using default theme.

### UC3 — Customize appearance

1. From extension preferences or modal:
   - Change theme
   - Adjust text size
   - Set aspect ratio (1:1, 4:5, 16:9)
   - Adjust background styles (blur, gradient)
   - Toggle watermark

### UC4 — Add attribution (optional)

Toggle a setting to auto-append:

- Page title
- Author (if detectable via metadata)
- URL (small footer)

### UC5 — Export formats

- Save As (PNG)
- Save As (JPEG)
- Copy to clipboard
- Send via macOS share sheet

---

## 7. Feature Set (Prioritized)

### P0 — Must Have

- Safari web extension
- Highlight → capture selected text
- Modal generator window
- Quote card renderer (HTML canvas or Swift layer)
- 6–12 curated themes
- Export as PNG/JPEG
- Auto-resize to Instagram / Twitter defaults
- Local theme preference storage
- Keyboard shortcut support
- Copy-to-clipboard

### P1 — Should Have

- Aspect ratio picker
- Attribution toggle
- Custom background color selector
- Custom brand color palette
- Adjustable padding
- Light/dark mode auto-adaptive themes

### P2 — Nice to Have

- Upload custom background images
- Image filters (blur, grain, duotone)
- Custom fonts using system-installed fonts
- Templates marketplace / theme packs
- Sync themes across devices using iCloud
- Export to video (for reels/stories)

### P3 — Future: Chrome extension

Architecture must allow:

- WebExtension portability
- Abstracted renderer
- Replacement of Safari App Extension wrapper

---

## 8. User Experience & UI Flow

### Flow A: Highlight → Quote

- User highlights text
- Right-click context menu → "Create QuoteCard"
- Modal appears centered over Safari window
- Live preview card
- User selects theme from horizontal theme selector
- Export buttons:
  - Save PNG
  - Copy
  - Share

### Flow B: Default theme quick export

- Highlight text
- ⇧⌘Q
- Notification: "Quote card copied to clipboard"

### Flow C: Settings Panel

Accessible in:

Safari → Preferences → Extensions → [Our App]

Settings include:

- Default theme
- Default export format
- Aspect ratio
- Watermark toggle / custom watermark
- Font scale slider
- Brand color palette (Pro)

---

## 9. Theme System (V1)

Themes should be implemented as JSON config objects:

```json
{
  "id": "soft-sand",
  "fontFamily": "Inter",
  "background": {
    "type": "solid",
    "color": "#FAF8F5"
  },
  "text": {
    "size": 32,
    "color": "#181818",
    "lineHeight": 1.35,
    "maxWidth": 80%
  },
  "padding": 48,
  "footer": {
    "enabled": true,
    "color": "#444",
    "opacity": 0.5
  }
}
```

Renderer must read theme JSON → use canvas/WebGL2 or SwiftUI drawing for pixel-perfect output.

**Themes included (examples):**

- Soft Sand (beige editorial; like your example)
- Serif Classic (New Yorker style)
- Midnight (dark background, neon accents)
- Minimal White (Apple aesthetic)
- Retro Print (grain texture + off-white)
- High Contrast (WCAG AA compliant)

---

## 10. Technical Architecture

### Safari App Extension architecture

- A macOS host app (Swift) containing:
  - UI for settings
  - Renderer (CoreGraphics or SwiftUI → image)
  - Theme storage
- Safari Web Extension (JS) handling:
  - Text selection
  - Context menu injection
  - Communication with host app via Safari WebExtension messaging

Renderer lives on macOS side for:

- Higher fidelity typography
- Performance
- More control over export resolution

### Renderer

Two implementation options:

#### Option A — SwiftUI → Bitmap (recommended)

**Pros:**

- Native Apple typography
- Crisp, anti-aliased output
- Clear path to theme packs
- Easy to add grain/blur/gradients

#### Option B — HTML Canvas in WebExtension

**Pros:**

- Simplifies Chrome port

**Cons:**

- Lower typographic control
- Harder to control strict pixel fidelity

**Recommendation:** build a renderer abstraction layer; use Swift first; prepare HTML canvas version for Chrome port.

### Communication

- WebExtension passes captured text to host app via message
- Host renders card in a sandbox window
- Host returns base64 image or file reference

### Storage

- User themes + settings stored in:
  - UserDefaults for simple values
  - Local JSON in app container for theme packs

---

## 11. Performance Requirements

- Modal must open within <150ms after selecting menu-item.
- Rendering must complete within <300ms for typical text length (~300 characters).
- Export size configurable but must support:
  - 1080×1080
  - 1350×1080
  - 1920×1080
- Must handle long quotes gracefully: smart text wrapping, scaling, ellipsis.

---

## 12. Error Handling

- If no text is selected → show inline tooltip "Select text to create a quote card."
- If text is too long → auto-suggest truncation or reduce font-size.
- If renderer fails → fallback to text-only card with default theme.

---

## 13. Privacy

- No network activity by default.
- No telemetry in V1.
- No storage of text selections.
- All rendering offline on-device.

---

## 14. Launch Plan

### V1 (4–6 weeks)

- Safari-only
- 6 themes
- Export PNG/JPEG
- Render in SwiftUI
- Basic settings
- Attribution toggle

### V1.1

- Custom brand colors
- Pro upgrade
- Theme store
- iCloud sync

### V2

- Cross-browser (Chrome, Arc, Edge)
- Template editing UI

---

## 15. Risks

1. Safari extension API friction (but manageable).
2. Maintaining dual renderer for Chrome port if needed.
3. Revenue sensitivity — need strong visuals to justify premium price.
4. Handling very long text selections gracefully.

---

## 16. Success Metrics

### Activation

- % of installs that create at least one card in first 24 hours

### Speed of workflow

- Time from highlight → generated export

### Retention

- Weekly active users
- % using shortcut workflow

### Revenue

- Extension purchase rate
- Pro theme pack attach rate
