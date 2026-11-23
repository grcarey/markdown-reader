import SwiftUI

// A bare `swift run` executable has no Info.plist, so macOS never makes it a regular
// foreground app: no menu bar, no Dock icon. Promote it on launch.
// It also owns the model, so files opened from Finder or the Dock reach the window.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()

    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first { model.open(url: url) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct MarkdownReaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private var model: AppModel { appDelegate.model }

    var body: some Scene {
        WindowGroup("Markdown Reader") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 600)
        }
        // Files opened from Finder go to the delegate; without this SwiftUI also opens a new window.
        .handlesExternalEvents(matching: [])
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
