# Xcode Project Setup Guide

This guide will walk you through creating the Xcode project for QuoteCard.

## Step 1: Create the Xcode Project with Safari Extension

1. Open Xcode
2. File → New → Project
3. Select "macOS" → **"Safari Extension App"** (not just "App")
4. Configure the project:
   - **Product Name:** QuoteCard
   - **Team:** (your team)
   - **Organization Identifier:** (your identifier, e.g., com.yourname)
   - **Bundle Identifier:** (auto-generated, e.g., com.yourname.QuoteCard)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Include Tests:** Optional
5. Save the project in: `/Users/mark/Developer/quotecard/app/`

**Note:** Using "Safari Extension App" automatically creates both the host app AND the extension target, so we don't need to add a separate extension target.

## Step 2: Replace Auto-Generated Files

After project creation, Xcode will have created template files. We'll replace these with our custom implementation.

### A. Replace Host App Files

1. In Xcode Project Navigator, expand the **QuoteCard** group
2. Delete these auto-generated files (Move to Trash):
   - `ContentView.swift` (we have our own)
   - `QuoteCardApp.swift` (we have our own)
3. Right-click **QuoteCard** group → **Add Files to "QuoteCard"**
4. Navigate to `/Users/mark/Developer/quotecard/app/QuoteCard/`
5. Select all `.swift` files:
   - `QuoteCardApp.swift`
   - `ContentView.swift`
   - `SettingsView.swift`
   - `RenderTypes.swift`
   - `ThemeRegistry.swift`
   - `QuoteCardRenderer.swift`
6. **Important:** Uncheck "Copy items if needed" (we want to reference the originals)
7. Add to target: **QuoteCard** (main app target)
8. Click Add

### B. Replace Extension Files

1. Expand the **QuoteCard Extension** group (or whatever Xcode named it)
2. Look for the auto-generated extension resources folder (usually contains manifest.json, etc.)
3. Delete all auto-generated extension files
4. Right-click **QuoteCard Extension** → **Add Files to "QuoteCard"**
5. Navigate to `/Users/mark/Developer/quotecard/extension/dist/`
6. Select all files and folders (manifest.json, background/, content/, popup/, etc.)
7. Check **"Create folder references"** (blue folders, not yellow groups)
8. Uncheck "Copy items if needed"
9. Add to target: **QuoteCard Extension**
10. Click Add

## Step 3: Verify Extension Info.plist (Optional)

The Safari Extension App template should have configured this correctly, but verify:

1. In Project Navigator, find **QuoteCard Extension** → **Info.plist**
2. Expand the `NSExtension` dictionary
3. Verify `NSExtensionPointIdentifier` is set to: `com.apple.Safari.web-extension`
4. This should already be correct from the template

## Step 4: Configure Signing & Capabilities

For both targets (QuoteCard and QuoteCard Extension):

1. Select the target from the target list
2. Go to **Signing & Capabilities** tab
3. Select your **Team** from the dropdown
4. **Hardened Runtime** should already be enabled by the template
5. If needed for development, under Hardened Runtime options:
   - Enable "Disable Library Validation"

## Step 5: Build and Run

1. Select the **"QuoteCard"** scheme from the scheme selector
2. Product → Run (or **Cmd+R**)
3. The QuoteCard app should launch with a welcome screen
4. Keep the app running
5. Open Safari
6. Go to Safari → Settings (or Preferences) → Extensions
7. Find **"QuoteCard"** and enable it

## Step 6: Test the Extension

1. In Safari, navigate to any webpage with text (try a blog post or news article)
2. Select some text (a sentence or paragraph)
3. Right-click → "Create QuoteCard"
4. A popup should open with a preview of your quote card
5. Try the controls:
   - Change aspect ratio (square/portrait/landscape)
   - Toggle attribution on/off
   - Click "Copy to Clipboard" or "Save PNG"

**Note:** At this stage, the extension uses a **mock JavaScript canvas renderer**. The preview you see is generated in the browser, not by the Swift renderer yet.

## Troubleshooting

**Extension doesn't appear in Safari:**
- Make sure the QuoteCard app is still running
- Try quitting and restarting Safari
- Check Safari → Settings → Extensions

**Context menu doesn't show "Create QuoteCard":**
- Make sure you've selected text first
- The menu item only appears when text is selected

**Build errors:**
- Check that all Swift files are added to the correct target
- Verify extension files are added as folder references (blue folders)
- Make sure your Team is selected in Signing & Capabilities

## Next Steps

Once the extension is working with the mock renderer, we'll:
1. Connect the Swift renderer via native messaging
2. Replace the mock canvas renderer with real Swift rendering
3. Test with various websites and text types
4. Create proper extension icons
