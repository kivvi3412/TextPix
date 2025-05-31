//
//  SettingView.swift
//  TextPix
//
//  Created by HAIRONG ZHU on 2025/4/29.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject private var appState = AppState.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // 快捷键设置
                GroupBox(label: Text("快捷键设置").font(.headline)) {
                    HStack {
                        Text("截图快捷键:")
                        Spacer()
                        KeyboardShortcuts.Recorder("", name: .capture)
                    }
                }
                
                // 大语言模型设置
                GroupBox(label: Text("LLM设置").font(.headline)) {
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("模型")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("输入模型名称", text: $appState.model)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("API 地址")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("输入API地址", text: $appState.endpoint)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("API 密钥")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("输入您的 API 密钥", text: $appState.apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                            .cornerRadius(8)
                    }
                    
                    // 是否开启推理(按钮)，以及推理强度列表 low medium high none
                    HStack(spacing: 2) {
                        Toggle(isOn: $appState.inferenceEnabled) {
                            Text("启用推理")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .toggleStyle(SwitchToggleStyle())
                        
                        Spacer()
                        Picker("推理强度", selection: $appState.inferenceLevel) {
                            Text("low").tag("low")
                            Text("medium").tag("medium")
                            Text("high").tag("high")
                            Text("none").tag("none")
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // OCR提示词设置
                GroupBox(label: Text("OCR系统提示词").font(.headline)) {
                    TextEditor(text: $appState.systemPrompt)
                        .font(.system(size: 12, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                        .cornerRadius(8)
                        .frame(minHeight: 100)
                }
                
                // 其他
                HStack {
                    // 选择框，是否自动copy
                    Toggle("OCR结果自动复制到剪切板", isOn: $appState.autoCopy)
                        
                    Spacer() // 将按钮推到右侧
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .padding()
                   
            
                
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    SettingsView()
}
