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
    }
}
