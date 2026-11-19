import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers

final class AppModel: ObservableObject {
    @Published var markdown: String = "# Welcome to Markdown Reader\n\nOpen a file or start typing..."
    @Published var currentFileURL: URL?
    @Published var fontSize: Double = 14
    @Published var recentFiles: [URL] = []

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
            self.load(url: url)
        }
    }

    func load(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            if let s = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.markdown = s
                    self.currentFileURL = url
                    self.addRecent(url: url)
                }
            }
        } catch {
            self.showError(error)
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
            self.addRecent(url: url)
        }
    }

    private func write(url: URL) {
        do {
            try markdown.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            self.showError(error)
        }
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

    private func addRecent(url: URL) {
        if let idx = recentFiles.firstIndex(of: url) {
            recentFiles.remove(at: idx)
        }
        recentFiles.insert(url, at: 0)
        if recentFiles.count > 20 { recentFiles.removeLast() }
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
