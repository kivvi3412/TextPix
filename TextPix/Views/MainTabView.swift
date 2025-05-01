//
//  MainTabView.swift
//  TextPix
//
//  Created by HAIRONG ZHU on 2025/5/1.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject private var appState = AppState.shared
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            OCRResultView()
                .tag(0)
                .tabItem {
                    Label("OCR", systemImage: "text.viewfinder")
                }
            
            ScreenshotView()
                .tag(1)
                .tabItem {
                    Label("Original", systemImage: "photo")
                }
            
            SettingsView()
                .tag(2)
                .tabItem {
                    Label("Setting", systemImage: "gear")
                }
        }
        .padding()
    }
}

#Preview {
    MainTabView()
}
