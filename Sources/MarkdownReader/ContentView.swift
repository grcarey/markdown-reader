import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HSplitView {
            EditorView(text: $model.markdown, fontSize: $model.fontSize)
            PreviewView(markdown: $model.markdown, fontSize: $model.fontSize)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppModel())
            .frame(width: 1000, height: 700)
    }
}
