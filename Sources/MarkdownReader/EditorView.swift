import SwiftUI

struct EditorView: View {
    @Binding var text: String
    @Binding var fontSize: Double

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Editor")
                    .font(.headline)
                Spacer()
            }
            TextEditor(text: $text)
                .font(.system(size: CGFloat(fontSize), weight: .regular, design: .monospaced))
                .padding(4)
                .background(Color(nsColor: NSColor.textBackgroundColor))
        }
        .padding(6)
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(text: .constant("# Hello"), fontSize: .constant(14))
            .frame(width: 400)
    }
}
