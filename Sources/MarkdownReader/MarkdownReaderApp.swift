import SwiftUI

// A bare `swift run` executable has no Info.plist, so macOS never makes it a regular
// foreground app: no menu bar, no Dock icon. Promote it on launch.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct MarkdownReaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Markdown Reader") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open…") { model.openFile() }
                    .keyboardShortcut("o")
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") { model.saveFile() }
                    .keyboardShortcut("s")
                Button("Save As…") { model.saveFileAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            CommandGroup(after: .saveItem) {
                Divider()
                Button("Export HTML…") { model.exportHTML() }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
}
