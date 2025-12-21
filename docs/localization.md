# Localization Guide

QuoteCard supports localization for both the Safari extension and the macOS host app. This guide explains how to add new languages.

---

## Overview

There are two separate localization systems:

| Component | System | Location |
|-----------|--------|----------|
| Safari Extension | WebExtension i18n API | `extension/public/_locales/` |
| macOS Host App | Apple .strings files | `app/QuoteCard/QuoteCard/*.lproj/` |

---

## Safari Extension Localization

The extension uses the standard WebExtension `_locales` system.

### File Structure

```
extension/public/_locales/
├── en/
│   └── messages.json
├── es/
│   └── messages.json
└── fr/
    └── messages.json
```

### Adding a New Language

1. Create a new folder in `extension/public/_locales/` using the [locale code](https://developer.chrome.com/docs/extensions/reference/i18n/#locales) (e.g., `es` for Spanish, `fr` for French, `de` for German)

2. Copy `en/messages.json` to your new folder

3. Translate all `"message"` values (keep the keys unchanged):

```json
{
  "extensionName": {
    "message": "QuoteCard",
    "description": "Extension name"
  },
  "appTagline": {
    "message": "Crea hermosas tarjetas de citas a partir del texto seleccionado",
    "description": "Extension description shown in browser settings"
  }
}
```

4. Run `npm run build` in the `extension/` folder

5. In Xcode, the `_locales` folder should update automatically (it's a folder reference)

6. Clean and rebuild the project

### Important Notes

- **Description limit**: Keep all `"description"` fields under 112 characters (Safari requirement)
- **Folder reference**: The `_locales` folder must be added to Xcode as a **folder reference** (blue folder icon), not a group (yellow folder icon)
- **Safari binding issue**: Always call `browser.i18n.getMessage()` directly in code, never assign it to a variable (Safari loses `this` context)

### Supported Locale Codes

Common codes: `en`, `es`, `fr`, `de`, `it`, `pt`, `ja`, `ko`, `zh_CN`, `zh_TW`

For Chinese, use `zh_CN` (Simplified) or `zh_TW` (Traditional), not just `zh`.

---

## macOS Host App Localization

The host app uses Apple's standard `.strings` file format.

### File Structure

```
app/QuoteCard/QuoteCard/
├── en.lproj/
│   └── Localizable.strings
├── es.lproj/
│   └── Localizable.strings
└── fr.lproj/
    └── Localizable.strings
```

### Adding a New Language

1. Create a new folder in `app/QuoteCard/QuoteCard/` named `{locale}.lproj` (e.g., `es.lproj`, `fr.lproj`)

2. Copy `en.lproj/Localizable.strings` to your new folder

3. Translate all values (keep the keys unchanged):

```
/* App name */
"appName" = "QuoteCard";

/* App tagline shown below the name */
"appTagline" = "Crea hermosas tarjetas de citas a partir del texto seleccionado";

/* Step 1 instruction */
"step1" = "Abre Safari y habilita la extensión QuoteCard";
```

4. In Xcode:
   - Right-click on the "QuoteCard" folder (app target)
   - Select "Add Files to 'QuoteCard'..."
   - Select your new `.lproj` folder
   - Choose "Create folder references"
   - Ensure "QuoteCard" target is checked
   - Click Add

5. Clean and rebuild

### String Format

The `.strings` file format is:

```
/* Comment describing the string */
"key" = "Translated value";
```

- Comments are optional but helpful for translators
- Each line ends with a semicolon
- Keys must match exactly what's used in code

---

## Testing Localizations

### Safari Extension

1. Change your Mac's language in System Settings > General > Language & Region
2. Restart Safari
3. The extension popup should display in the new language

### macOS Host App

1. Change your Mac's language in System Settings > General > Language & Region
2. Restart the QuoteCard app
3. The app window should display in the new language

Alternatively, test without changing system language:

```bash
# Run app with specific language
defaults write com.markallen.QuoteCard AppleLanguages "(es)"
# Then launch the app

# Reset to system default
defaults delete com.markallen.QuoteCard AppleLanguages
```

---

## Current Strings

### Extension (`messages.json`)

| Key | English |
|-----|---------|
| `extensionName` | QuoteCard |
| `extensionDescription` | Create beautiful, shareable quote images from selected webpage text |
| `actionTitle` | Create QuoteCard |
| `loadingMessage` | Generating quote card... |
| `themeLabel` | Theme |
| `formatLabel` | Format |
| `formatSquare` | Square |
| `formatPortrait` | Portrait |
| `formatLandscape` | Landscape |
| `copyButton` | Copy to Clipboard |
| `copyingButton` | Copying... |
| `copiedButton` | Copied! |
| `downloadButton` | Download |
| `savingButton` | Saving... |
| `savedButton` | Saved! |
| `emptyStateTitle` | No Text Selected |
| `emptyStateDescription` | Select some text on the page, then click the QuoteCard icon to continue. |
| `closeButton` | Close |
| `errorConnection` | Please reload the page and try again |
| `errorTabAccess` | Could not access current tab |
| `errorRenderFailed` | Failed to render quote card |
| `errorCopyFailed` | Failed to copy to clipboard |
| `errorSaveFailed` | Failed to save image |
| `errorUnexpected` | An unexpected error occurred |

### Host App (`Localizable.strings`)

| Key | English |
|-----|---------|
| `appName` | QuoteCard |
| `appTagline` | Create beautiful quote cards from selected text |
| `step1` | Open Safari and enable the QuoteCard extension |
| `step2` | Select text on any webpage |
| `step3` | Right-click and choose 'Create QuoteCard' |
| `openSafariExtensions` | Open Safari Extensions |
