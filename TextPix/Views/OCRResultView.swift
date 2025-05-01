//
//  MarkDownDisplay.swift
//  TextPix
//
//  Created by HAIRONG ZHU on 2025/5/1.
//

import SwiftUI
import WebKit
import Combine

struct OCRResultView: View {
    @ObservedObject private var appState = AppState.shared
    
    var body: some View {
        Group {
            if appState.isProcessing {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("正在识别中...")
                        .font(.headline)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    MarkdownLatexView(markdownText: appState.markdownText)
                        .frame(minHeight: 100)
                        .border(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    Divider()
                    
                    TextEditor(text: $appState.markdownText)
                        .font(.system(size: 14, design: .monospaced))
                        .padding(4)
                        .border(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    Button("Copy to Clipboard") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(appState.markdownText, forType: .string)
                    }
                    .padding(.bottom)
                }
            }
        }
    }
    
    struct MarkdownLatexView: NSViewRepresentable {
        let markdownText: String
        
        func makeNSView(context: NSViewRepresentableContext<MarkdownLatexView>) -> WKWebView {
            let configuration = WKWebViewConfiguration()
            let preferences = WKPreferences()
            
            // 现代方式启用 JavaScript
            let webpagePreferences = WKWebpagePreferences()
            webpagePreferences.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences = webpagePreferences
            
            configuration.preferences = preferences
            configuration.userContentController.add(context.coordinator, name: "heightUpdate")
            
            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.navigationDelegate = context.coordinator
            
            // macOS版本特有设置
            webView.allowsMagnification = true
            
            // 初始化时加载HTML模板
            loadHTMLTemplate(webView: webView)
            
            return webView
        }
        
        func updateNSView(_ webView: WKWebView, context: NSViewRepresentableContext<MarkdownLatexView>) {
            // 只有在页面已加载完成后才执行更新
            if context.coordinator.isHTMLLoaded {
                updateMarkdownContent(webView: webView)
            }
        }
        
        private func loadHTMLTemplate(webView: WKWebView) {
            guard let base = Bundle.main.resourceURL else {
                print("找不到主资源目录")
                return
            }
            
            let html = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <script src="marked.min.js"></script>
                    <script src="katex.min.js"></script>
                    <script src="auto-render.min.js"></script>
                    <link rel="stylesheet" href="katex.min.css">
                    <style>
                        body {
                            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                            padding: 10px;
                            margin: 0;
                            font-size: 16px;
                            line-height: 1.5;
                            background-color: #ffffff;
                        }
                        pre {
                            background-color: #f5f5f5;
                            padding: 10px;
                            border-radius: 5px;
                            overflow-x: auto;
                        }
                        code {
                            font-family: Menlo, Monaco, 'Courier New', monospace;
                        }
                        .katex-display {
                            overflow-x: auto;
                            overflow-y: hidden;
                            padding: 5px 0;
                        }
                    </style>
                </head>
                <body>
                    <div id="content"></div>
                    <script>
                        // 定义更新Markdown内容的函数
                        function updateMarkdown(markdown) {
                            document.getElementById('content').innerHTML = marked.parse(markdown);
                            
                            renderMathInElement(document.body, {
                                delimiters: [
                                    {left: '$$', right: '$$', display: true},
                                    {left: '$', right: '$', display: false}
                                ],
                                throwOnError: false
                            });
                            
                            // 通知Swift页面高度变化
                            window.webkit.messageHandlers.heightUpdate.postMessage(document.body.scrollHeight);
                        }
                    </script>
                </body>
                </html>
                """
            
            webView.loadHTMLString(html, baseURL: base)
        }
        
        private func updateMarkdownContent(webView: WKWebView) {
            // 转义特殊字符
            let escapedMarkdown = markdownText.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            
            // 使用JavaScript更新内容而不是重新加载整个页面
            let updateScript = "updateMarkdown(\"\(escapedMarkdown)\");"
            webView.evaluateJavaScript(updateScript) { (result, error) in
                if let error = error {
                    print("更新Markdown内容时出错: \(error.localizedDescription)")
                }
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
            var parent: MarkdownLatexView
            var isHTMLLoaded = false
            
            init(_ parent: MarkdownLatexView) {
                self.parent = parent
                super.init()
            }
            
            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                // 网页加载完成后, 标记状态并更新初始内容
                isHTMLLoaded = true
                parent.updateMarkdownContent(webView: webView)
            }
            
            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                // 处理JavaScript消息
                if message.name == "heightUpdate", let height = message.body as? CGFloat {
                    print("内容高度: \(height)")
                    // 这里可以执行更多基于高度的逻辑, 如调整视图大小
                }
            }
        }
    }
}
