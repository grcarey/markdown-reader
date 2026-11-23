# Markdown Reader (macOS)

This is a minimal native macOS Markdown reader built with SwiftUI.

Features:

- Split editor and live preview, with a toolbar switch to show the editor only, the preview only or both (remembered between launches)
- Scroll sync: scrolling either pane scrolls the other, with top-level headings lined up in both
- Open, Save and Save As
- Export to HTML
- Font size adjustment
- Mermaid diagrams in the preview
- Links to other `.md` files open in the reader, with a Back button (Cmd+[) to return
- Refresh (Cmd+R) reloads the file from disk, and a banner shows when another app has changed it
- Drag a `.md` file from Finder onto the window or the Dock icon to open it

Requirements:

- macOS 12+ (Monterey) and Xcode 14+ recommended
- Swift 5.7+

Run in Xcode:

1. Open the folder in Xcode (File → Open) and select `Package.swift`.
2. Choose the `MarkdownReader` scheme and press Run.

Run from terminal (quick):

```bash
swift run
```

Run the tests:

```bash
swift test
```

Install as an app (in /Applications and on the Dock, and set as the default for `.md` files):

```bash
scripts/install-app.sh
```

Re-run it after changes. The version comes from `VERSION`; the build number is the commit count.

Notes:

- The preview is a `WKWebView` using bundled `marked` and `mermaid` (works offline). Mermaid code blocks render as diagrams.
- Scroll sync maps between panes through the source line of each top-level heading (`Sources/ScrollMap`). Headings inside lists or blockquotes are not used. A file with no headings, or with headings the panes cannot match (such as raw HTML headings), falls back to proportional sync.
- The app checks the open file for changes every 2 seconds.

Ideas:

- Open a dropped folder in a folder browser
- Add folder browser and file tree
- Add export to PDF and a nicer HTML template
- Add preferences (theme / default font)
