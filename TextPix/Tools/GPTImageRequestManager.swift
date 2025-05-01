import Foundation
import SwiftUI

@MainActor
class GPTImageRequestManager {
    private let appState = AppState.shared
    
    // 将NSImage转换为Base64字符串
    private func convertImageToBase64(_ image: NSImage) -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            return nil
        }
        
        return data.base64EncodedString()
    }
    
    // 使用图片和系统提示词发送API请求
    @MainActor
    func requestCompletion(image: NSImage, systemPrompt: String) async throws {
        guard let base64Image = convertImageToBase64(image) else {
            throw NSError(domain: "GPTImageRequestManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法将图片转换为base64格式"])
        }
        
        appState.isProcessing = true
        
        // 使用defer确保函数退出时isLoading设为false
        defer {
            appState.isProcessing = false
        }
        
        // 创建API请求URL
        let url = URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(appState.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 创建请求体
        let requestBody: [String: Any] = [
            "model": appState.model,
            "messages": [
                [
                    "role": "system",
                    "content": appState.systemPrompt
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw NSError(domain: "GPTImageRequestManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "请求体序列化失败"])
        }
        
        // 发送请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查响应是否有效
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "GPTImageRequestManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "无效的HTTP响应"])
            }
            
            if httpResponse.statusCode != 200 {
                let errorString = String(data: data, encoding: .utf8) ?? "未知错误"
                throw NSError(domain: "GPTImageRequestManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString])
            }
            
            // 解析响应
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(APIResponse.self, from: data)
            
            if let content = apiResponse.choices.first?.message.content {
                await MainActor.run {
                    appState.markdownText = content
                }
            } else {
                await MainActor.run {
                    appState.markdownText = "响应中没有内容"
                }
            }
            
        } catch {
            await MainActor.run {
                appState.markdownText = "错误: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // 用于解码API响应的结构体
    struct APIResponse: Codable {
        let id: String
        let object: String
        let created: Int
        let model: String
        let choices: [Choice]
        let usage: Usage
    }
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}
