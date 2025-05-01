//
//  ScreenshotManager.swift
//  TextPix
//
//  Created by HAIRONG ZHU on 2025/4/29.
//

import SwiftUI

@MainActor
class ScreenshotManager: ObservableObject {
    private let appState = AppState.shared
    private let ocrService = OCRService() // 添加 OCR 服务实例

    func captureWithSystemPicker() async {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
                     .appendingPathComponent(UUID().uuidString + ".png")

        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments   = ["-i", "-x", tmp.path]   // -x 静默、-i 交互
        task.launch()
        task.waitUntilExit()

        if FileManager.default.fileExists(atPath: tmp.path),
           let img = NSImage(contentsOf: tmp) {
            appState.screenshotImage = img
            // 截图成功后，调用 OCR 服务
            Task {
                await ocrService.performOCR(on: img)
            }
        }
    }
}

