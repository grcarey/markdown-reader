import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    @Binding var markdown: String
    @Binding var fontSize: Double
    @EnvironmentObject var model: AppModel

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "link")
        config.userContentController.add(context.coordinator, name: "scroll")
        config.userContentController.add(context.coordinator, name: "anchors")
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        context.coordinator.webView = web
        model.scrollPreview = { [weak coordinator = context.coordinator] y in
            coordinator?.webView?.evaluateJavaScript("syncTo(\(y))")
        }
        // Load the template once; baseURL is the resources directory so the scripts load by relative src.
        if let page = Coordinator.template {
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

        // "scroll" carries the preview's scroll offset in pixels, "anchors" its heading positions. Links resolve against the open file: .md files open here, everything else in its default app.
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "scroll" {
                if let y = message.body as? Double { model?.scrollEditor?(y) }
                return
            }
            if message.name == "anchors" {
                if let d = message.body as? [String: Any], let lines = d["lines"] as? [Int],
                   let ys = d["ys"] as? [Double], let max = d["max"] as? Double {
                    model?.previewAnchors = (lines, ys, max)
                }
                return
            }
            guard let href = message.body as? String,
                  let url = URL(string: href, relativeTo: model?.currentFileURL)?.absoluteURL else { return }
            if AppModel.isMarkdown(url) {
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

        // Only the template (and its #anchors) may load. Any other navigation is a file dropped on the page: cancel it and open Markdown in the reader.
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let url = action.request.url
            if let url, url.path == Self.template?.path { return decisionHandler(.allow) }
            decisionHandler(.cancel)
            if let url { model?.openDropped([url]) }
        }

        static let template = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "Resources")

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
