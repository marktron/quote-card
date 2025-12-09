# QuoteCard WebExtension

This directory contains the Safari WebExtension code for QuoteCard.

## Structure

```
extension/
  src/
    background/        # Background script (context menu, keyboard shortcuts)
    content/           # Content script (text selection)
    popup/             # Popup UI (preview and export)
    shared/            # Shared types and utilities
  public/
    manifest.json      # Extension manifest
    icons/             # Extension icons
```

## Development

1. Install dependencies:
   ```bash
   npm install
   ```

2. Build the extension:
   ```bash
   npm run build
   ```

3. Watch for changes during development:
   ```bash
   npm run watch
   ```

## Testing

The extension includes a mock canvas renderer for testing the UI flow before the Swift renderer is connected.

### Load in Safari

1. Build the extension
2. Open Safari → Preferences → Advanced → Show Develop menu
3. Develop → Allow Unsigned Extensions
4. Open the Xcode project (coming soon)
5. Run the project to install the extension

## Next Steps

- [ ] Create Xcode project with Safari Web Extension target
- [ ] Implement Swift renderer with Soft Sand theme
- [ ] Replace mock renderer with native messaging to Swift app
- [ ] Create placeholder icons (currently missing)
