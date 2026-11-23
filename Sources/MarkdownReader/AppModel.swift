import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers

final class AppModel: ObservableObject {
    private static let welcome = "# Welcome to Markdown Reader\n\nOpen a file or start typing..."
    @Published var markdown: String = welcome
    private var savedText = welcome
    @Published var currentFileURL: URL?
    @Published var fontSize: Double = 14
    @Published var history: [URL] = []
    @Published var changedOnDisk = false
    private var loadedModDate: Date?
    // Scroll sync hooks: each pane registers its own setter (fraction 0...1). Plain closures, so no re-renders.
    var scrollEditor: ((Double) -> Void)?
    var scrollPreview: ((Double) -> Void)?

    // ponytail: polls the open file's modification date every 2s; switch to a DispatchSource watcher if polling ever matters.
    init() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.checkDisk() }
    }

    private func modDate(_ url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private func markInSync(_ url: URL) {
        loadedModDate = modDate(url)
        changedOnDisk = false
    }

    private func checkDisk() {
        guard !changedOnDisk, let url = currentFileURL, let date = modDate(url) else { return }
        if let loaded = loadedModDate, date > loaded { changedOnDisk = true }
    }

    // Open a markdown file using NSOpenPanel
    func openFile() {
        let panel = NSOpenPanel()
        if #available(macOS 11.0, *) {
            var types: [UTType] = [.plainText]
            if let md = UTType(filenameExtension: "md") { types.append(md) }
            panel.allowedContentTypes = types
        } else {
            panel.allowedFileTypes = ["txt", "md", "markdown"]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            self.open(url: url)
        }
    }

    // Opening a file directly starts a new link chain.
    func open(url: URL) {
        if load(url: url) { history.removeAll() }
    }

    // Follow a link from the current file, remembering where we came from.
    func follow(url: URL) {
        let from = currentFileURL
        if load(url: url), let from { history.append(from) }
    }

    // Re-read the current file from disk, keeping the Back history.
    func reload() {
        guard let url = currentFileURL else { return }
        load(url: url)
    }

    func goBack() {
        guard let previous = history.last, load(url: previous) else { return }
        history.removeLast()
    }

    @discardableResult
    func load(url: URL) -> Bool {
        guard confirmDiscard() else { return false }
        do {
            let data = try Data(contentsOf: url)
            guard let s = String(data: data, encoding: .utf8) else { return false }
            // A different file starts at the top; a refresh keeps the reader's place.
            if url != currentFileURL { scrollEditor?(0); scrollPreview?(0) }
            markdown = s
            savedText = s
            currentFileURL = url
            markInSync(url)
            return true
        } catch {
            self.showError(error)
            return false
        }
    }

    func saveFile() {
        if let url = currentFileURL {
            write(url: url)
        } else {
            saveFileAs()
        }
    }

    func saveFileAs() {
        let panel = NSSavePanel()
        if #available(macOS 11.0, *) {
            var types: [UTType] = [.plainText]
            if let md = UTType(filenameExtension: "md") { types.append(md) }
            panel.allowedContentTypes = types
        } else {
            panel.allowedFileTypes = ["md", "markdown", "txt"]
        }
        panel.nameFieldStringValue = "Untitled.md"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            self.currentFileURL = url
            self.write(url: url)
        }
    }

    private func write(url: URL) {
        do {
            try markdown.write(to: url, atomically: true, encoding: .utf8)
            savedText = markdown
            markInSync(url)
        } catch {
            self.showError(error)
        }
    }

    private func confirmDiscard() -> Bool {
        guard markdown != savedText else { return true }
        let alert = NSAlert()
        alert.messageText = "Discard unsaved changes?"
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    func exportHTML() {
        // Convert markdown to AttributedString then to NSAttributedString and HTML
        do {
            let swiftAttr = try AttributedString(markdown: markdown)
            let ns = NSAttributedString(swiftAttr)
            let htmlData = try ns.data(from: NSRange(location: 0, length: ns.length),
                                       documentAttributes: [.documentType: NSAttributedString.DocumentType.html])

            let panel = NSSavePanel()
            if #available(macOS 11.0, *) {
                if let htmlType = UTType(filenameExtension: "html") { panel.allowedContentTypes = [htmlType] }
            } else {
                panel.allowedFileTypes = ["html"]
            }
            panel.nameFieldStringValue = (currentFileURL?.deletingPathExtension().lastPathComponent ?? "Export") + ".html"
            panel.begin { response in
                guard response == .OK, let url = panel.url else { return }
                do {
                    try htmlData.write(to: url)
                } catch {
                    self.showError(error)
                }
            }
        } catch {
            self.showError(error)
        }
    }

    private func showError(_ error: Error) {
        showErrorMessage(error.localizedDescription)
    }

    private func showErrorMessage(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = message
            alert.runModal()
        }
    }
}
