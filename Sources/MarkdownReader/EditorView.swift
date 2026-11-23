import SwiftUI
import ScrollMap

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
// ponytail: heading-anchored sync, top-level headings only (none in lists or quotes), laid out on demand at every scroll event;
// very large files may need cached anchor offsets, invalidated on text, font or width change.
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
        // Only on a size change: re-applying the font on every keystroke restyles the whole text.
        let font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
        if tv.font != font { tv.font = font }
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

        // Matching (editor y, preview y) breakpoints: each preview heading's source line laid out in the text view.
        private func breakpoints(_ scroll: NSScrollView) -> (editor: [Double], preview: [Double], max: Double)? {
            guard let tv = scroll.documentView as? NSTextView, let lm = tv.layoutManager, let tc = tv.textContainer else { return nil }
            let a = parent.model.previewAnchors
            let ns = tv.string as NSString
            var ys: [Double] = [], line = 0, idx = 0
            for target in a.lines {
                while line < target {
                    let r = ns.range(of: "\n", range: NSRange(location: idx, length: ns.length - idx))
                    if r.location == NSNotFound { break }
                    idx = r.upperBound
                    line += 1
                }
                let chars = NSRange(location: min(idx, max(ns.length - 1, 0)), length: min(1, ns.length))
                lm.ensureLayout(forCharacterRange: chars)
                let g = lm.glyphRange(forCharacterRange: chars, actualCharacterRange: nil)
                ys.append(Double(lm.boundingRect(forGlyphRange: g, in: tc).minY + tv.textContainerOrigin.y))
            }
            let emax = Double(max(tv.frame.height - scroll.contentView.bounds.height, 0))
            let b = scrollBreakpoints(editor: ys, preview: a.ys, editorMax: emax, previewMax: a.max)
            return (b.editor, b.preview, emax)
        }

        // Scrolls set by the other pane are ignored for 150 ms (a timestamp, as a no-op scroll fires no event).
        @objc func scrolled() {
            guard Date().timeIntervalSince(lastProgrammatic) > 0.15, let scroll, let b = breakpoints(scroll) else { return }
            let y = Double(scroll.contentView.bounds.origin.y)
            parent.model.scrollPreview?(mapScroll(y, from: b.editor, to: b.preview))
        }

        func scrollTo(_ previewY: Double) {
            guard let scroll, let b = breakpoints(scroll) else { return }
            lastProgrammatic = Date()
            let y = mapScroll(previewY, from: b.preview, to: b.editor)
            scroll.contentView.scroll(to: NSPoint(x: 0, y: CGFloat(y)))
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
