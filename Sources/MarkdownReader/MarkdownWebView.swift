import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    @Binding var markdown: String
    @Binding var fontSize: Double

    func makeNSView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        web.navigationDelegate = context.coordinator
        context.coordinator.webView = web
        // Load the template once; baseURL is the resources directory so the scripts load by relative src.
        if let page = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "Resources") {
            web.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
        }
        return web
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(markdown: markdown, fontSize: fontSize)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
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
