import SwiftUI

struct PreviewView: View {
    @Binding var markdown: String
    @Binding var fontSize: Double

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Preview")
                    .font(.headline)
                Spacer()
            }

            // WKWebView preview: marked renders markdown, mermaid renders diagrams (both bundled, offline)
            MarkdownWebView(markdown: $markdown, fontSize: $fontSize)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(6)
    }
}

struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView(markdown: .constant("# Heading\n\nHello **world**"), fontSize: .constant(14))
            .frame(width: 400)
    }
}
