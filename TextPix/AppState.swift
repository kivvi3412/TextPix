//
//  AppState.swift
//  TextPix
//
//  Created by HAIRONG ZHU on 2025/4/30.
//

import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    // 核心数据, 不做持久化
    @Published var screenshotImage: NSImage?
    @Published var markdownText: String = ""
    @Published var isProcessing: Bool = false
    
    // 界面状态
    @Published var selectedTab: Int = UserDefaults.standard.integer(forKey: "selectedTab") {
        didSet {
            UserDefaults.standard.set(selectedTab, forKey: "selectedTab")
        }
    }
    
    // 自动复制到剪切板
    @Published var autoCopy: Bool = UserDefaults.standard.bool(forKey: "autoCopy") {
        didSet {
            UserDefaults.standard.set(autoCopy, forKey: "autoCopy")
        }
    }
    
    // LLM 参数
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "apiKey")
    ?? "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "apiKey")
        }
    }
    @Published var model: String = UserDefaults.standard.string(forKey: "model")
    ?? "qwen2.5-vl-7b-instruct" {
        didSet {
            UserDefaults.standard.set(model, forKey: "model")
        }
    }
    @Published var endpoint: String = UserDefaults.standard.string(forKey: "endpoint")
    ?? "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions" {
        didSet {
            UserDefaults.standard.set(endpoint, forKey: "endpoint")
        }
    }
    @Published var inferenceEnabled: Bool = UserDefaults.standard.bool(forKey: "inferenceEnabled") {
        didSet {
            UserDefaults.standard.set(inferenceEnabled, forKey: "inferenceEnabled")
        }
    }

    @Published var inferenceLevel: String = UserDefaults.standard.string(forKey: "inferenceLevel")
    ?? "medium" {
        didSet {
            UserDefaults.standard.set(inferenceLevel, forKey: "inferenceLevel")
        }
    }
        
    
    @Published var systemPrompt: String = UserDefaults.standard.string(forKey: "systemPrompt")
    ?? """
        1. OCR输出为markdown文本 (如果有序和无序列表使用markdown标准语法)
        2. 输出格式也要像图片中的完全一致, 禁止自己换行和自行使用$$, 输出文本的空格换行必须和图片完全一致
        3. 如果它是一个块方程用 $$ 符号包裹, 例:
        $$
        \\int \\sec x \\mathrm{~d} x=\\ln |\\sec x+\\tan x|+C
        $$
        4. 内联方程, 使用 $...$ 的行内数学模式输出, 使用 $ 符号包裹 , 例: $f^{\\prime}\\left(x_0\\right)$
        5. 如果是表格, 请直接使用 markdown 表格语法输出
        6. 注意缩进层次, 输出呈现的样子必须与原图保持一致
        7. 禁止使用 \\[...\\] 输出, 不要漏东西, 完整整齐的输出图片所有内容
        """ {
            didSet {
                UserDefaults.standard.set(systemPrompt, forKey: "systemPrompt")
            }
        }
    
    // 单例
    static let shared = AppState()
    private init() {}
}
