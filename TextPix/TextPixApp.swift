//
//  TextPixApp.swift
//  TextPix
//
//  Created by HAIRONG ZHU on 2025/4/29.
//

import SwiftUI
import KeyboardShortcuts


@main
struct TextPixApp: App {
    @StateObject private var appState = AppState.shared
    private let screenshotManager = ScreenshotManager()
    private let keyboardManager: KeyboardManager
    
    init() {
        keyboardManager = KeyboardManager(screenshotManager: screenshotManager)
    }
    
    var body: some Scene {
        MenuBarExtra("TextPix", systemImage: "text.viewfinder") {
            MainTabView()
                .frame(minWidth: 600, minHeight: 450)
        }
        .menuBarExtraStyle(.window)
    }
}
