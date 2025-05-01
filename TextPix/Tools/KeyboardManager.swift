//
//  KeyboardManager.swift
//  TextPix
//
//  Created by HAIRONG ZHU on 2025/4/30.
//

import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    static let capture = Self(
        "capture",
        default: .init(.two, modifiers: [.command, .shift])
    )
}

class KeyboardManager {
    private let screenshotManager: ScreenshotManager
    
    init(screenshotManager: ScreenshotManager) {
        self.screenshotManager = screenshotManager
        setupShortcuts()
    }
    
    private func setupShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .capture) { [weak self] in
            guard let self = self else { return }
            Task {
                await self.screenshotManager.captureWithSystemPicker()
            }
        }
    }
}
