# macOS Markdown Reader — Project Plan

A concise plan to build a native macOS Markdown reader using SwiftUI (recommended).

## Goals

- Native, responsive macOS app for reading and editing Markdown
- Live HTML preview with fast rendering
- File system integration: open/save, folder browser, drag & drop
- Theming, font sizing, and export (PDF/HTML)
- Simple packaging for distribution

## Milestones

- [ ] Create project scaffold (SwiftUI macOS app)
  - Xcode macOS App target using Swift + SwiftUI
  - App entry, AppDelegate/Scene management

- [ ] Implement main UI: sidebar, editor, live Markdown preview
  - Left sidebar: file list / folders
  - Editor: multi-line text editor with syntax features
  - Preview: WebView rendering via `WKWebView` or native renderer
  - Split view and resizable panes

- [ ] Add file open/save, drag & drop, and folder browser
  - `NSOpenPanel` / `NSSavePanel` support
  - Drag & drop files into app and onto sidebar
  - Watch folders for changes (optional)

- [ ] Support themes, font sizing, and export (PDF/HTML)
  - Light/Dark themes using system appearance
  - Font size adjustment and line wrapping
  - Export currently open document to PDF and HTML

- [ ] Package app for distribution and add README
  - Create a simple `README.md` with build/run steps
  - Provide an Xcode `Archive`/notarization note (manual step)

- [ ] Run build & basic manual tests
  - Verify macOS 12+ compatibility
  - Verify opening, editing, saving, and exporting

## Tech choices (recommended)

- Language: Swift 5+ (SwiftUI)
- Markdown renderer: `Down` (Swift wrapper for cmark) or Apple's `Markdown` APIs
- Preview: `WKWebView` for HTML/CSS rendering or `Text` for simple rendering

## Initial next steps

1. Scaffold the Xcode SwiftUI macOS app and commit the initial project.
2. Implement the split editor + preview and wire up a sample Markdown renderer.

---

Created for: macOS native Markdown reader — let me know if you want a different tech stack (Electron, AppKit, etc.).
