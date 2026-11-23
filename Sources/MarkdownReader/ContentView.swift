import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("viewMode") private var viewMode = "both"

    // A hidden pane is torn down; its scroll closure captures the coordinator weakly, so it becomes a no-op.
    var body: some View {
        HSplitView {
            if viewMode != "preview" {
                EditorView(text: $model.markdown, fontSize: $model.fontSize)
            }
            if viewMode != "editor" {
                PreviewView(markdown: $model.markdown, fontSize: $model.fontSize)
            }
        }
        .safeAreaInset(edge: .top) {
            if model.changedOnDisk {
                HStack {
                    Image(systemName: "exclamationmark.arrow.circlepath")
                    Text("\(model.currentFileURL?.lastPathComponent ?? "This file") has changed on disk.")
                    Spacer()
                    Button("Refresh") { model.reload() }
                }
                .padding(8)
                .background(Color.yellow.opacity(0.25))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { model.goBack() }) { Label("Back", systemImage: "chevron.left") }
                    .help(model.history.last.map { "Back to \($0.lastPathComponent)" } ?? "Back")
                    .keyboardShortcut("[")
                    .disabled(model.history.isEmpty)
            }
            ToolbarItem(placement: .navigation) {
                Button(action: { model.reload() }) { Label("Refresh", systemImage: "arrow.clockwise") }
                    .help("Reload the file from disk")
                    .keyboardShortcut("r")
                    .disabled(model.currentFileURL == nil)
            }
            ToolbarItem(placement: .automatic) {
                Picker("View", selection: $viewMode) {
                    Label("Editor", systemImage: "doc.plaintext").tag("editor")
                    Label("Preview", systemImage: "doc.richtext").tag("preview")
                    Label("Both", systemImage: "rectangle.split.2x1").tag("both")
                }
                .pickerStyle(.segmented)
                .help("Show the editor, the preview or both")
            }
            ToolbarItemGroup(placement: .automatic) {
                Text("Font")
                Slider(value: $model.fontSize, in: 10...30)
                    .frame(width: 140)
            }
        }
        .padding(6)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppModel())
            .frame(width: 1000, height: 700)
    }
}
