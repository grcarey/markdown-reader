import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    @Binding var markdown: String
    @Binding var fontSize: Double
    @EnvironmentObject var model: AppModel

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "link")
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        context.coordinator.webView = web
        // Load the template once; baseURL is the resources directory so the scripts load by relative src.
        if let page = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "Resources") {
            web.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
        }
        return web
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.model = model
        context.coordinator.update(markdown: markdown, fontSize: fontSize)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        weak var model: AppModel?

        // Links resolve against the open file: .md files open here, everything else in its default app.
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let href = message.body as? String,
                  let url = URL(string: href, relativeTo: model?.currentFileURL)?.absoluteURL else { return }
            if url.isFileURL, ["md", "markdown"].contains(url.pathExtension.lowercased()) {
                model?.follow(url: url)
            } else {
                NSWorkspace.shared.open(url)
            }
        }
        private var markdown = ""
        private var fontSize = 14.0
        private var ready = false

        func update(markdown: String, fontSize: Double) {
            self.markdown = markdown
            self.fontSize = fontSize
            if ready { flush() }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            ready = true
            flush()
        }

        private func flush() {
            // JSON-encode the string so any markdown content is a safe JS literal.
            guard let data = try? JSONEncoder().encode(markdown),
                  let literal = String(data: data, encoding: .utf8) else { return }
            webView?.evaluateJavaScript("render(\(literal), \(fontSize))")
        }
    }
}
