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
                    MarkdownLatexView(markdownText: $appState.markdownText)
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
        @Binding var markdownText: String // 建议改为 Binding，以便双向数据流，如果不需要可改回 let
        
        func makeNSView(context: NSViewRepresentableContext<MarkdownLatexView>) -> WKWebView {
            let configuration = WKWebViewConfiguration()
            let webpagePreferences = WKWebpagePreferences()
            webpagePreferences.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences = webpagePreferences
            
            // 注册回调，用于获取页面高度
            configuration.userContentController.add(context.coordinator, name: "heightUpdate")
            
            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.navigationDelegate = context.coordinator
            
            // macOS 设置：允许透明背景，这样更好看
            webView.setValue(false, forKey: "drawsBackground")
            
            loadHTMLTemplate(webView: webView)
            return webView
        }
        
        func updateNSView(_ webView: WKWebView, context: NSViewRepresentableContext<MarkdownLatexView>) {
            // 当内容加载完毕后更新
            if context.coordinator.isHTMLLoaded {
                updateMarkdownContent(webView: webView)
            }
        }
        
        // MARK: - 核心修复 1: Base64 传输
        private func updateMarkdownContent(webView: WKWebView) {
            // 使用 Base64 编码，彻底避免反斜杠和引号转义地狱
            guard let data = markdownText.data(using: .utf8) else { return }
            let base64String = data.base64EncodedString()
            
            // 调用我们自己在 HTML 里写的 updateContent 函数
            let script = "updateContent('\(base64String)');"
            
            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    print("JS Error: \(error.localizedDescription)")
                }
            }
        }
        
        // MARK: - 核心修复 2: Notion 风格模板 + 公式保护 JS
        private func loadHTMLTemplate(webView: WKWebView) {
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                
                <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
                <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
                <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"></script>
                
                <style>
                    /* Notion/Obsidian 风格 CSS */
                    :root {
                        --bg-color: transparent;
                        --text-color: #37352f; /* Notion 黑 */
                        --code-bg: #f7f6f3;
                    }
                    
                    @media (prefers-color-scheme: dark) {
                        :root {
                            --text-color: #ffffff; /* 纯白 */
                            --code-bg: #2c2c2c;
                        }
                    }
                    
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji";
                        font-size: 16px;
                        line-height: 1.7;
                        color: var(--text-color);
                        background-color: var(--bg-color);
                        padding: 20px;
                        margin: 0;
                        overflow-wrap: break-word; /* 防止长公式撑破布局 */
                    }
                    
                    /* 代码块样式 */
                    pre {
                        background-color: var(--code-bg);
                        padding: 16px;
                        border-radius: 8px;
                        overflow-x: auto;
                        font-size: 14px;
                        border: 1px solid rgba(0,0,0,0.05);
                    }

                    code {
                        font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, Courier, monospace;
                        background-color: rgba(135,131,120,0.15);
                        padding: 0.2em 0.4em;
                        border-radius: 3px;
                        font-size: 85%;
                    }
                    
                    pre code {
                        background-color: transparent;
                        padding: 0;
                        border-radius: 0;
                        font-size: 100%;
                    }
                    
                    /* 数学公式样式优化 */
                    .katex-display {
                        overflow-x: auto;
                        overflow-y: hidden;
                        padding: 0.5em 0;
                        margin: 1em 0;
                        /* 让滚动条好看点 */
                        scrollbar-width: thin; 
                    }
                    
                    /* 引用块样式 */
                    blockquote {
                        border-left: 3px solid currentcolor;
                        margin: 1em 0;
                        padding-left: 1em;
                        opacity: 0.8;
                    }
                    
                    img {
                        max-width: 100%;
                        border-radius: 4px;
                    }
                </style>
            </head>
            <body>
                <div id="content"></div>
                
                <script>
                    // 1. Base64 解码 (支持中文)
                    function b64DecodeUnicode(str) {
                        return decodeURIComponent(atob(str).split('').map(function(c) {
                            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
                        }).join(''));
                    }
            
                    function updateContent(base64Markdown) {
                        let rawMarkdown = "";
                        try {
                            rawMarkdown = b64DecodeUnicode(base64Markdown);
                        } catch(e) {
                            console.error("Decode failed", e);
                            return;
                        }
            
                        // 2. 【关键】公式保护机制
                        // 这里的 trick 是：先把 $$...$$ 里的内容替换成占位符，不让 marked 解析它。
                        
                        const mathBlocks = [];
                        // 保护 $$...$$ 块级公式
                        rawMarkdown = rawMarkdown.replace(/\\$\\$([\\s\\S]*?)\\$\\$/g, function(match) {
                            mathBlocks.push(match);
                            return "%%%MATH_BLOCK_" + (mathBlocks.length - 1) + "%%%";
                        });
            
                        // 3. 解析 Markdown
                        let html = marked.parse(rawMarkdown);
            
                        // 4. 还原公式
                        html = html.replace(/%%%MATH_BLOCK_(\\d+)%%%/g, function(match, id) {
                            return mathBlocks[id];
                        });
            
                        document.getElementById('content').innerHTML = html;
            
                        // 5. 渲染 KaTeX
                        renderMathInElement(document.getElementById('content'), {
                            delimiters: [
                                {left: '$$', right: '$$', display: true},
                                {left: '$', right: '$', display: false},
                                {left: '\\\\(', right: '\\\\)', display: false},
                                {left: '\\\\[', right: '\\\\]', display: true}
                            ],
                            throwOnError: false,
                            trust: true // 允许特定命令
                        });
                        
                        // 6. 通知高度更新
                        setTimeout(() => {
                             window.webkit.messageHandlers.heightUpdate.postMessage(document.body.scrollHeight);
                        }, 100);
                    }
                </script>
            </body>
            </html>
            """
            
            webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
            var parent: MarkdownLatexView
            var isHTMLLoaded = false
            
            init(_ parent: MarkdownLatexView) {
                self.parent = parent
            }
            
            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                isHTMLLoaded = true
                parent.updateMarkdownContent(webView: webView)
            }
            
            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                if message.name == "heightUpdate", let _ = message.body as? CGFloat {
                    // 如果你需要根据内容高度动态调整WebView高度，在这里处理
                    // parent.dynamicHeight = height
                }
            }
        }
    }
}
