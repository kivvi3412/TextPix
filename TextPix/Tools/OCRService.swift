//
//  OCRService.swift
//  TextPix
//
//  Created by Trae AI on 2025/5/2.
//

import Foundation
import SwiftUI

@MainActor
class OCRService {
    private let gptManager = GPTImageRequestManager()
    private let appState = AppState.shared

    func performOCR(on image: NSImage) async {
        await MainActor.run {
            appState.markdownText = "正在识别中..."
            appState.isProcessing = true
            appState.selectedTab = 0 // 切换到OCR结果标签页
        }

        do {
            // 使用 GPTImageRequestManager 发送请求
            // 注意：GPTImageRequestManager 内部已经处理了 appState.isProcessing 和 appState.ocrText 的更新
            // 这里我们只需要调用它，它会在完成或失败时更新 AppState
            try await gptManager.requestCompletion(image: image, systemPrompt: appState.systemPrompt)
            // 成功时，gptManager 内部会更新 appState.markdownText
            print("OCR 请求成功")
            
            if (appState.autoCopy) {
                // 自动复制到剪切板
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(appState.markdownText, forType: .string)
            }
        } catch {
            // 失败时，gptManager 内部会更新 appState.markdownText 为错误信息
            print("OCR 请求失败: \(error.localizedDescription)")
            // 确保即使出错也更新状态
            appState.isProcessing = false
            // 保留 gptManager 设置的错误信息
        }
    }
}
