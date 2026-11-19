import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @State private var sidebarWidth: CGFloat = 220

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 180, idealWidth: sidebarWidth, maxWidth: 320)

            HSplitView {
                EditorView(text: $model.markdown, fontSize: $model.fontSize)
                PreviewView(markdown: $model.markdown, fontSize: $model.fontSize)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { model.openFile() }) { Label("Open", systemImage: "folder") }
                Button(action: { model.saveFile() }) { Label("Save", systemImage: "square.and.arrow.down") }
                Button(action: { model.saveFileAs() }) { Text("Save As") }
                Button(action: { model.exportHTML() }) { Label("Export HTML", systemImage: "doc.richtext") }
                Divider()
                Text("Font")
                Slider(value: $model.fontSize, in: 10...30)
                    .frame(width: 140)
            }
        }
        .padding(6)
    }

    var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Files")
                    .font(.headline)
                Spacer()
            }

            Button("Open…") { model.openFile() }
            Button("Save") { model.saveFile() }
            Button("Save As…") { model.saveFileAs() }
            Divider()
            Text("Recent")
                .font(.subheadline)
            List(model.recentFiles, id: \ .self) { url in
                Button(action: { model.load(url: url) }) {
                    Text(url.lastPathComponent)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(8)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppModel())
            .frame(width: 1000, height: 700)
    }
}
