# QuoteCard Technical Implementation Guide

## 0. High-level architecture

Two main pieces:

1. macOS host app (Swift / SwiftUI)
   - Owns the renderer and settings.
   - Provides a UI for preferences.
   - Exposes an interface for:
     - renderQuoteCard(request: RenderRequest) -> RenderResult
     - getSettings(), updateSettings()
2. Safari Web Extension (TypeScript/JS)
   - Injected into pages.
   - Reads current text selection.
   - Adds context-menu item + keyboard shortcut.
   - Sends message with RenderRequest to host app.
   - Receives RenderResult (image) and triggers export (download/share or copy).

Later, for Chrome/Edge, you replace the macOS host with:

- A small native helper, or
- A pure WebExtension with an HTML `<canvas>` renderer and unified TS core.

Keep the rendering interface stable so both implementations can be swapped.

---

## 1. Repository structure

Example mono-repo layout:

``` txt
quote-card/
  app/
    QuoteCardHostApp/        # macOS host (SwiftUI)
    QuoteCardRenderer/       # Swift renderer framework
    QuoteCardThemes/         # Theme JSONs + Swift wrappers
  extension/
    webextension/
      src/
        background.ts
        contentScript.ts
        ui/
          popup.tsx
        shared/
          messaging.ts
          types.ts
      manifest.json
      package.json
      tsconfig.json
  shared/
    theme-spec/              # JSON schema / docs for themes
    design/                  # Figma exports, sample images
```

Chrome port will use extension/webextension as its base.

---

## 2. Data model & messaging contracts

### 2.1 Types

Define shared TS types in shared/types.ts and mirror them in Swift.

```ts
export type AspectRatio = "square" | "portrait" | "landscape";

export interface RenderSettings {
  themeId: string;
  aspectRatio: AspectRatio;
  exportFormat: "png" | "jpeg";
  includeAttribution: boolean;
}

export interface RenderRequest {
  id: string;                // uuid to correlate responses
  text: string;
  sourceTitle?: string;
  sourceUrl?: string;
  createdAt: number;         // epoch ms
  settingsOverride?: Partial<RenderSettings>;
}

export interface RenderResult {
  id: string;
  success: boolean;
  errorMessage?: string;
  // Base64 image, e.g. data:image/png;base64,...
  dataUrl?: string;
}
```

Swift equivalents (use Codable):

```swift
struct RenderSettings: Codable {
    let themeId: String
    let aspectRatio: String  // "square" | "portrait" | "landscape"
    let exportFormat: String // "png" | "jpeg"
    let includeAttribution: Bool
}

struct RenderRequest: Codable {
    let id: String
    let text: String
    let sourceTitle: String?
    let sourceUrl: String?
    let createdAt: Int64
    let settingsOverride: RenderSettings?
}

struct RenderResult: Codable {
    let id: String
    let success: Bool
    let errorMessage: String?
    let dataUrl: String?
}
```

Keep this contract versioned if you add fields later.

---

## 3. Safari Web Extension

### 3.1 Manifest

Use Safari-compatible WebExtension manifest v2 (v3 support is still evolving).

**Key points:**

```json
{
  "manifest_version": 2,
  "name": "QuoteCard",
  "version": "1.0.0",
  "description": "Create shareable images from selected text.",
  "permissions": ["contextMenus", "activeTab", "tabs", "storage"],
  "background": {
    "scripts": ["background.js"],
    "persistent": false
  },
  "browser_action": {
    "default_title": "Create QuoteCard",
    "default_popup": "popup.html"
  },
  "commands": {
    "create-quotecard": {
      "suggested_key": {
        "default": "Shift+Command+Q"
      },
      "description": "Create shareable image from text selection"
    }
  },
  "icons": {...},
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["contentScript.js"],
      "run_at": "document_idle"
    }
  ]
}
```

Safari's Xcode integration will wrap this in a macOS app bundle.

### 3.2 Content script

**Responsibilities:**

- Read current text selection.
- Provide a function getSelectionPayload() for background script to call.

**Example:**

```ts
function getSelectionText(): string | null {
  const selection = window.getSelection();
  if (!selection || selection.rangeCount === 0) return null;
  return selection.toString().trim() || null;
}

function getMetadata() {
  const title = document.title || undefined;
  const url = window.location.href || undefined;
  return { title, url };
}

// Expose via message passing
browser.runtime.onMessage.addListener((msg, _sender) => {
  if (msg.type === "REQUEST_SELECTION") {
    const text = getSelectionText();
    const meta = getMetadata();
    return Promise.resolve({
      type: "SELECTION_RESPONSE",
      text,
      sourceTitle: meta.title,
      sourceUrl: meta.url
    });
  }
});
```

### 3.3 Background script

**Responsibilities:**

- Register context menu and keyboard command.
- When triggered, ask content script for selection.
- Construct RenderRequest.
- Send to Safari host app via messaging API.
- Handle RenderResult and perform export.

**Context menu:**

```ts
browser.contextMenus.create({
  id: "create-quotecard",
  title: "Create QuoteCard",
  contexts: ["selection"]
});

browser.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId === "create-quotecard" && tab?.id != null) {
    await handleCreateQuote(tab.id);
  }
});

browser.commands.onCommand.addListener(async (command) => {
  if (command === "create-quotecard") {
    const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
    if (tab?.id != null) {
      await handleCreateQuote(tab.id);
    }
  }
});

async function handleCreateQuote(tabId: number) {
  const selectionResp = await browser.tabs.sendMessage(tabId, { type: "REQUEST_SELECTION" });

  if (!selectionResp.text) {
    // Optional: show notification "Select some text first"
    return;
  }

  const settings = await browser.storage.sync.get(["defaultSettings"]);
  const request: RenderRequest = {
    id: crypto.randomUUID(),
    text: selectionResp.text,
    sourceTitle: selectionResp.sourceTitle,
    sourceUrl: selectionResp.sourceUrl,
    createdAt: Date.now(),
    settingsOverride: null
  };

  // Safari-specific: send to native host app
  browser.runtime.sendNativeMessage("QuoteCardHost", {
    type: "RENDER_REQUEST",
    payload: request
  });
}
```

**Handling results** (Safari will deliver messages back to background or popup depending on implementation):

```ts
browser.runtime.onMessage.addListener((msg) => {
  if (msg.type === "RENDER_RESULT") {
    const result = msg.payload as RenderResult;
    if (!result.success || !result.dataUrl) {
      // show error notification
      return;
    }
    triggerDownload(result.dataUrl, `quote-${result.id}.png`);
  }
});

function triggerDownload(dataUrl: string, filename: string) {
  const a = document.createElement("a");
  a.href = dataUrl;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
}
```

Safari's native messaging wire-up is handled in Xcode; JS sees sendNativeMessage / message events.

---

## 4. macOS Host App (SwiftUI)

### 4.1 Project setup

In Xcode:

1. Create macOS App project, Swift + SwiftUI.
2. Add Safari Web Extension target.
3. Link the WebExtension folder.
4. Create a framework target QuoteCardRenderer for rendering logic.
5. Enable App Sandbox, "Incoming Connections" not required.

### 4.2 Native Messaging / message handling

Safari App Extensions use SFSafariExtensionHandler or WebExtension bridging.

You'll implement something akin to:

```swift
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        guard let item = context.inputItems.first as? NSExtensionItem else { return }
        guard let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any] else { return }

        if let jsonString = message["payload"] as? String {
            handleMessage(jsonString: jsonString) { responseJSON in
                let responseItem = NSExtensionItem()
                responseItem.userInfo = [ SFExtensionMessageKey: ["payload": responseJSON] ]
                context.completeRequest(returningItems: [responseItem], completionHandler: nil)
            }
        }
    }

    private func handleMessage(jsonString: String, completion: @escaping (String) -> Void) {
        // Decode request
        let decoder = JSONDecoder()
        guard let data = jsonString.data(using: .utf8),
              let req = try? decoder.decode(RenderRequest.self, from: data) else {
            let errorResult = RenderResult(id: UUID().uuidString, success: false, errorMessage: "Invalid request", dataUrl: nil)
            let json = String(data: try! JSONEncoder().encode(errorResult), encoding: .utf8)!
            completion(json)
            return
        }

        Task.detached {
            let result = await QuoteCardRenderer.shared.render(request: req)
            let jsonData = try! JSONEncoder().encode(result)
            let json = String(data: jsonData, encoding: .utf8)!
            completion(json)
        }
    }
}
```

JS side and Swift side both treat payload as JSON string.

---

## 5. Renderer (SwiftUI)

### 5.1 Theme model

Swift wrapper around JSON theme config:

```swift
struct Theme: Codable {
    let id: String
    let name: String
    let fontName: String
    let backgroundColorHex: String
    let textColorHex: String
    let footerColorHex: String?
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowOpacity: Double
    // etc.
}
```

Themes stored as themes.json in app bundle. At launch, load into ThemeRegistry.

Example theme:

```json
{
      "id": "neon-night",
      "name": "Neon Night",
      "description": "Bold dark gradient with neon accent; tuned for social feeds and short, high-impact quotes.",
      "category": "social",
      "font": {
        "family": "SF Pro Rounded",
        "weight": 600,
        "fallback": "system",
        "quoteFontFamily": "SF Pro Rounded",
        "footerFontFamily": "SF Pro Text"
      },
      "background": {
        "type": "gradient",
        "gradient": {
          "type": "linear",
          "angle": 135,
          "colors": ["#070B19", "#151C3A", "#190B28"]
        }
      },
      "overlay": {
        "enabled": true,
        "vignette": {
          "innerOpacity": 0.0,
          "outerOpacity": 0.65
        }
      },
      "text": {
        "color": "#F9FAFF",
        "maxFontSize": 44,
        "minFontSize": 26,
        "lineHeight": 1.3,
        "alignment": "left",
        "maxWidthRatio": 0.76,
        "useLargeOpeningQuote": true,
        "openingQuoteColor": "#4AF3C3"
      },
      "footer": {
        "enabled": true,
        "color": "#9DA5FF",
        "fontSize": 16,
        "opacity": 0.85,
        "alignment": "right",
        "separator": "—"
      },
      "layout": {
        "padding": 60,
        "borderRadius": 40,
        "shadowBlur": 60,
        "shadowOffsetY": 30,
        "shadowOpacity": 0.6,
        "shadowColor": "#000000"
      }
    }
```

### 5.2 Render pipeline

1. Map AspectRatio to canvas size:

   ```swift
   func canvasSize(for aspect: String, scale: CGFloat = 3.0) -> CGSize {
     switch aspect {
     case "square": return CGSize(width: 1080 * scale, height: 1080 * scale)
     case "portrait": return CGSize(width: 1080 * scale, height: 1350 * scale)
     case "landscape": return CGSize(width: 1920 * scale, height: 1080 * scale)
     default: return CGSize(width: 1080 * scale, height: 1080 * scale)
     }
   }
   ```

2. Build a SwiftUI view that lays out the quote:

   ```swift
   struct QuoteCardView: View {
   let text: String
   let sourceTitle: String?
   let sourceUrl: String?
   let theme: Theme

   var body: some View {
       ZStack {
           Color(theme.backgroundColor)
           VStack(alignment: .leading, spacing: 24) {
               Text(text)
                   .font(.custom(theme.fontName, size: 40))
                   .foregroundColor(theme.textColor)
                   .lineSpacing(4)
                   .fixedSize(horizontal: false, vertical: true)

               if let title = sourceTitle {
                   Text(title)
                       .font(.system(size: 20, weight: .medium))
                       .foregroundColor(theme.footerColor)
                       .opacity(0.7)
               }
           }
           .padding(theme.padding)
       }
       .cornerRadius(theme.cornerRadius)
       .shadow(radius: 24, y: 12)
   }
   }
   ```

3. Render to NSImage:

   ```swift
   final class QuoteCardRenderer {

       static let shared = QuoteCardRenderer()

       func render(request: RenderRequest) async -> RenderResult {
           let settings = request.settingsOverride ?? SettingsStore.shared.defaultRenderSettings
           guard let theme = ThemeRegistry.shared.theme(withId: settings.themeId) else {
               return RenderResult(id: request.id, success: false, errorMessage: "Theme not found", dataUrl: nil)
           }

           let size = canvasSize(for: settings.aspectRatio)
           let view = QuoteCardView(
               text: request.text,
               sourceTitle: settings.includeAttribution ? request.sourceTitle : nil,
               sourceUrl: settings.includeAttribution ? request.sourceUrl : nil,
               theme: theme
           )

           let image = renderSwiftUIView(view, size: size)
           let data: Data?
           if settings.exportFormat == "jpeg" {
               data = image.jpegData(compressionQuality: 0.95)
           } else {
               data = image.pngData()
           }

           guard let imageData = data else {
               return RenderResult(id: request.id, success: false, errorMessage: "Encoding failed", dataUrl: nil)
           }

           let base64 = imageData.base64EncodedString()
           let prefix = settings.exportFormat == "jpeg" ? "data:image/jpeg;base64," : "data:image/png;base64,"
           return RenderResult(id: request.id, success: true, errorMessage: nil, dataUrl: prefix + base64)
       }

       private func renderSwiftUIView(_ view: some View, size: CGSize) -> NSImage {
           let hostingView = NSHostingView(rootView: view)
           hostingView.frame = CGRect(origin: .zero, size: size)

           let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)!
           hostingView.cacheDisplay(in: hostingView.bounds, to: rep)
           let image = NSImage(size: size)
           image.addRepresentation(rep)
           return image
       }
   }
   ```

(A bit of glue code omitted, but this is the core.)

---

## 6. Settings & Persistence

### 6.1 Storage

Use UserDefaults for simple scalar values and Codable for structured settings.

```swift
class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    var defaultRenderSettings: RenderSettings {
        get {
            if let data = defaults.data(forKey: "defaultRenderSettings"),
               let s = try? JSONDecoder().decode(RenderSettings.self, from: data) {
                return s
            }
            return RenderSettings(
                themeId: "soft-sand",
                aspectRatio: "square",
                exportFormat: "png",
                includeAttribution: true
            )
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: "defaultRenderSettings")
        }
    }
}
```

Expose a simple SwiftUI preferences UI bound to this store.

### 6.2 Bridge to WebExtension

When WebExtension needs settings (for immediate overrides), either:

- Let host app apply settings (simpler), or
- Cache a subset in browser.storage.sync and keep synchronized via messages.

Simplest V1: WebExtension always sends only text + metadata, host app always uses its own stored settings (no override). Popover UI for theme selection can live in host app.

---

## 7. Export & User interaction

### 7.1 Export behavior variants

Two modes:

1. **Quick export (default)**
   - Extension auto-downloads PNG to default downloads folder, or copies to clipboard if you prefer.
2. **Interactive export**
   - Host app presents a small floating window showing the generated image and buttons: "Copy", "Save…", "Share…".

**Implementation of copy/share in macOS:**

```swift
func copyToClipboard(_ image: NSImage) {
    let pb = NSPasteboard.general
    pb.clearContents()
    pb.writeObjects([image])
}

func shareImage(_ image: NSImage, from view: NSView) {
    let picker = NSSharingServicePicker(items: [image])
    picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
}
```

Choose which mode to invoke based on a setting (e.g. "Quick Export: Clipboard / File / Interactive").

---

## 8. Future Chrome port

To keep the path open:

1. Keep the WebExtension code browser-agnostic.
   - Use the webextension-polyfill browser API.
   - Avoid Safari-only APIs in TS.
2. Create an HTML Canvas renderer that conforms to same RenderRequest → RenderResult interface.

   **Example:**

   ```ts
   async function renderInCanvas(req: RenderRequest, theme: Theme): Promise<RenderResult> {
     const canvas = document.createElement("canvas");
     const ctx = canvas.getContext("2d")!;
     // set size based on aspect
     // draw background, text, footer…
     const dataUrl = canvas.toDataURL("image/png");
     return { id: req.id, success: true, dataUrl };
   }
   ```

3. Abstract renderer selection.

   ```ts
   async function renderQuote(req: RenderRequest): Promise<RenderResult> {
     if (isSafari()) {
       return renderViaNativeHost(req);
     } else {
       return renderInCanvas(req, await loadTheme(req.settingsOverride?.themeId));
     }
   }
   ```

4. **Chrome build**
   - Reuse extension/webextension.
   - Swap manifest's host permissions / icons.
   - Remove Safari macOS host dependency.

---

## 9. Testing strategy

### 9.1 Unit tests

- **Swift**
  - Theme loading / decoding.
  - Text wrapping & truncation for extreme lengths.
  - RenderRequest → RenderResult pipeline.
- **TS**
  - Selection parsing (including weird pages / iframes).
  - Messaging contract: verify payload shape.
  - triggerDownload logic.

### 9.2 Snapshot/render tests

- Generate fixed set of cards for known inputs and store as golden images.
- On CI, re-render and compare within small tolerance using image diff (e.g. pixelmatch or custom script on macOS).

### 9.3 Manual QA matrix

Test across:

- macOS versions that support current Safari (at least two).
- Different fonts and languages (Latin, CJK, RTL basic sanity).
- Long quotes, single-word quotes, emoji, URLs.
- Light/dark macOS modes.

---

## 10. Packaging & distribution

1. Sign macOS app with Developer ID.
2. Enable "Safari Web Extensions" capability.
3. Archive and distribute via Mac App Store.
   - App bundle includes host app + Safari Web Extension.
4. On first run:
   - Show onboarding: "Open Safari → Preferences → Extensions → Enable QuoteCard."
