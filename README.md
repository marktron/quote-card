# QuoteCard

A premium Safari extension for generating beautiful, shareable quote images from selected webpage text.

## Project Status

🚧 **Currently in initial development**

We have completed:
- ✅ Project structure and repository setup
- ✅ TypeScript WebExtension with text selection and context menu
- ✅ Interactive popup UI with preview
- ✅ Swift renderer with Soft Sand theme
- ✅ Basic settings UI

Next steps:
- ⏳ Create Xcode project and integrate files
- ⏳ Connect WebExtension to Swift renderer via native messaging
- ⏳ Test end-to-end on various websites
- ⏳ Create proper extension icons
- ⏳ Add additional themes

## Repository Structure

```
quotecard/
├── docs/                    # Product documentation
│   ├── PRD.md              # Product requirements
│   └── technical-plan.md   # Technical implementation guide
├── extension/              # Safari WebExtension (TypeScript)
│   ├── src/
│   │   ├── background/     # Background script
│   │   ├── content/        # Content script (text selection)
│   │   ├── popup/          # Popup UI
│   │   └── shared/         # Shared types
│   ├── public/
│   │   └── manifest.json   # Extension manifest
│   └── dist/               # Built extension (generated)
├── app/                    # macOS host app (Swift/SwiftUI)
│   └── QuoteCard/          # Swift source files
├── shared/                 # Shared resources
│   └── themes/             # Theme definitions
├── XCODE_SETUP.md         # Xcode project setup guide
└── README.md              # This file
```

## Development Setup

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Node.js 18+ and npm
- Safari 17.0 or later

### WebExtension Development

1. Install dependencies:
   ```bash
   cd extension
   npm install
   ```

2. Build the extension:
   ```bash
   npm run build
   ```

3. For development with auto-rebuild:
   ```bash
   npm run watch
   ```

The built extension will be in `extension/dist/`.

### Xcode Project Setup

Follow the detailed guide in [`XCODE_SETUP.md`](./XCODE_SETUP.md) to:
1. Create the Xcode project
2. Add Safari Web Extension target
3. Link the WebExtension files
4. Configure signing and capabilities

### Running the Extension

1. Build both the WebExtension and the Xcode project
2. Run the QuoteCard app from Xcode
3. Enable the extension in Safari → Preferences → Extensions
4. Test on any webpage with selectable text

## Architecture

### Two-Part System

1. **WebExtension (TypeScript)**
   - Runs in Safari browser context
   - Handles text selection and user interaction
   - Presents popup UI with preview
   - Communicates with native app via messaging

2. **Native App (Swift/SwiftUI)**
   - macOS host application
   - Renders quote cards using SwiftUI
   - Manages themes and settings
   - Provides high-fidelity typography

### Rendering Pipeline

1. User selects text on webpage
2. Content script captures selection + metadata
3. Background script creates RenderRequest
4. Request sent to Swift renderer via native messaging
5. Swift app renders using SwiftUI → bitmap
6. Returns base64 data URL to WebExtension
7. Popup displays preview and export options

## Current Features

- ✅ Text selection from any webpage
- ✅ Context menu integration ("Create QuoteCard")
- ✅ Keyboard shortcut (⇧⌘Q)
- ✅ Interactive popup with live preview
- ✅ Mock canvas renderer (for testing UI)
- ✅ Soft Sand theme
- ✅ Multiple aspect ratios (square, portrait, landscape)
- ✅ Attribution toggle
- ✅ Copy to clipboard
- ✅ Save as PNG/JPEG
- ✅ Settings persistence

## Testing

### Manual Testing Workflow

1. Build the extension: `cd extension && npm run build`
2. Run the Xcode project
3. Enable extension in Safari
4. Navigate to test sites:
   - Blog posts (Medium, Substack)
   - News articles
   - Documentation sites
   - Wikipedia
5. Select text and create quote cards
6. Test various text lengths and formats
7. Try different themes and aspect ratios

### Test Cases

- [ ] Short quotes (1-2 sentences)
- [ ] Medium quotes (paragraph)
- [ ] Long quotes (multiple paragraphs)
- [ ] Text with emojis
- [ ] Text with special characters
- [ ] Text from different languages
- [ ] Pages with complex layouts
- [ ] Pages with iframes
- [ ] Dark mode websites

## Known Issues / TODOs

- [ ] Extension icons not yet created (Safari shows placeholder)
- [ ] Native messaging bridge not yet implemented (using mock renderer)
- [ ] Only one theme available (Soft Sand)
- [ ] No error handling for very long text
- [ ] Settings not yet synced between extension and native app

## Contributing

This is currently a private development project. Documentation and code structure are being maintained for future expansion.

## License

TBD
