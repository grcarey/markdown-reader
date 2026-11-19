import SwiftUI

@main
struct MarkdownReaderApp: App {
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
        }
    }
}
