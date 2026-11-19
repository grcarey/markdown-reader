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
        guard confirmDiscard() else { return }
        do {
            let data = try Data(contentsOf: url)
            if let s = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.markdown = s
                    self.savedText = s
                    self.currentFileURL = url
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
        }
    }

    private func write(url: URL) {
        do {
            try markdown.write(to: url, atomically: true, encoding: .utf8)
            savedText = markdown
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
