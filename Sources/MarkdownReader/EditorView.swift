import SwiftUI

struct EditorView: View {
    @Binding var text: String
    @Binding var fontSize: Double
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Editor")
                    .font(.headline)
                Spacer()
            }
            SyncedTextEditor(text: $text, fontSize: fontSize, model: model)
                .padding(4)
                .background(Color(nsColor: NSColor.textBackgroundColor))
        }
        .padding(6)
    }
}

// NSTextView in place of TextEditor so the scroll position is reachable for syncing with the preview.
// ponytail: proportional sync (scroll fraction); long diagrams or images skew the mapping, heading-anchored sync is the upgrade.
struct SyncedTextEditor: NSViewRepresentable {
    @Binding var text: String
    var fontSize: Double
    let model: AppModel

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        let tv = scroll.documentView as! NSTextView
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.allowsUndo = true
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.isAutomaticSpellingCorrectionEnabled = false
        tv.backgroundColor = .textBackgroundColor
        tv.string = text
        scroll.contentView.postsBoundsChangedNotifications = true
        context.coordinator.scroll = scroll
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.scrolled),
                                               name: NSView.boundsDidChangeNotification, object: scroll.contentView)
        model.scrollEditor = { [weak coordinator = context.coordinator] in coordinator?.scrollTo($0) }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        let tv = scroll.documentView as! NSTextView
        tv.font = .monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
        // Only set when it differs, so typing keeps the cursor and scroll position.
        if tv.string != text { tv.string = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyncedTextEditor
        weak var scroll: NSScrollView?
        private var lastProgrammatic = Date.distantPast

        init(_ parent: SyncedTextEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }

        // Scrolls set by the other pane are ignored for 150 ms (a timestamp, as a no-op scroll fires no event).
        @objc func scrolled() {
            guard Date().timeIntervalSince(lastProgrammatic) > 0.15, let scroll,
                  let doc = scroll.documentView else { return }
            let range = doc.frame.height - scroll.contentView.bounds.height
            let f = range > 0 ? scroll.contentView.bounds.origin.y / range : 0
            parent.model.scrollPreview?(min(max(Double(f), 0), 1))
        }

        func scrollTo(_ f: Double) {
            guard let scroll, let doc = scroll.documentView else { return }
            lastProgrammatic = Date()
            let range = max(doc.frame.height - scroll.contentView.bounds.height, 0)
            scroll.contentView.scroll(to: NSPoint(x: 0, y: CGFloat(f) * range))
            scroll.reflectScrolledClipView(scroll.contentView)
        }
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(text: .constant("# Hello"), fontSize: .constant(14))
            .environmentObject(AppModel())
            .frame(width: 400)
    }
}
