# Markdown Reader (macOS)

This is a minimal native macOS Markdown reader built with SwiftUI.

Features:
- Split editor + live preview
- Open / Save / Save As
- Export to HTML
- Font size adjustment
- Mermaid diagrams in preview

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

Install as an app (in /Applications and on the Dock, and set as the default for `.md` files):

```bash
scripts/install-app.sh
```

Re-run it after changes. The version comes from `VERSION`; the build number is the commit count.

Notes:
- The preview is a `WKWebView` using bundled `marked` and `mermaid` (works offline). Mermaid code blocks render as diagrams.

Next steps you might want me to do:
- Add drag & drop for files and folders
- Add folder browser and file tree
- Add export to PDF and a nicer HTML template
- Add preferences (theme / default font)
