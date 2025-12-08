# Shared Resources

This directory contains resources shared between the Safari extension (TypeScript) and the macOS app (Swift).

## themes.json

Source of truth for theme definitions.

**Used by:**
- **Swift App**: `app/Pullquote/ThemeRegistry.swift` loads this JSON file at runtime
- **Extension**: Theme data is duplicated in `extension/src/shared/themes.ts` (Safari doesn't support JSON module imports)

**To add a new theme:**

1. **Add to `themes.json`** - This is the canonical source
2. **Update TypeScript** - Manually sync the theme to `extension/src/shared/themes.ts` in the `THEMES_DATA` object
   - Combine `font.family` and `font.fallback` into a single CSS font stack
3. **Rebuild extension**: `cd extension && npm run build`
4. **Rebuild Xcode project**

**Structure:**
```json
{
  "id": "theme-id",
  "name": "Display Name",
  "description": "...",
  "font": {
    "family": "Font Name",
    "fallback": "fallback-stack",
    "weight": 500
  },
  "background": { "color": "#HEX" },
  "text": {
    "color": "#HEX",
    "fontSize": 40,
    "lineHeight": 1.4
  },
  "footer": {
    "enabled": true,
    "color": "#HEX",
    "fontSize": 18,
    "opacity": 0.75
  },
  "layout": {
    "padding": 64
  }
}
```

**Note**: Due to Safari's MIME type restrictions on JSON imports, theme data must be manually kept in sync between `themes.json` (Swift) and `themes.ts` (TypeScript). Future enhancement: create a build script to auto-generate `themes.ts` from `themes.json`.
