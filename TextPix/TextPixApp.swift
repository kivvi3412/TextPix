//
//  TextPixApp.swift
//  TextPix
//
//  Created by HAIRONG ZHU on 2025/4/29.
//

import SwiftUI
import KeyboardShortcuts
import UserNotifications
import Sparkle

private struct UpdaterKey: EnvironmentKey {
    static let defaultValue: SPUUpdater? = nil
}

extension EnvironmentValues {
    var updater: SPUUpdater? {
        get { self[UpdaterKey.self] }
        set { self[UpdaterKey.self] = newValue }
    }
}

@main
struct TextPixApp: App {
    @StateObject private var appState = AppState.shared
    private let screenshotManager = ScreenshotManager()
    private let keyboardManager: KeyboardManager
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        keyboardManager = KeyboardManager(screenshotManager: screenshotManager)
        _ = NotificationManager.shared
        
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        MenuBarExtra("TextPix", systemImage: "text.viewfinder") {
            MainTabView()
                .frame(minWidth: 600, minHeight: 450)
                .environment(\.updater, updaterController.updater)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
