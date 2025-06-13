//
//  NotificationManager.swift
//  TextPix
//
//  Created by HAIRONG ZHU on 2025/6/13.
//

import Foundation
import UserNotifications

/// 统一的本地通知封装
@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()        // 单例
    private override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self                       // 让前台也能弹横幅
        Task { await requestAuthorization() }
    }
    
    /// 通知权限申请（只在第一次调用时弹窗）
    private func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // 权限弹窗被系统阻止时也不影响主流程
            print("Notification authorization error: \(error.localizedDescription)")
        }
    }
    
    /// 发送 OCR 结果通知
    func sendOCRResult(success: Bool, errorMessage: String? = nil) {
        let content       = UNMutableNotificationContent()
        content.title     = success ? "识别成功" : "识别失败"
        content.body      = success ? "文本已生成并可复制使用。" : (errorMessage ?? "未知错误")
        content.sound     = .none
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil      // 立即送达
        )
        UNUserNotificationCenter.current().add(request)
    }

}
