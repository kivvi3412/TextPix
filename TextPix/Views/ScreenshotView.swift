//
//  ScreenshotView.swift
//  TextPix
//
//  Created by HAIRONG ZHU on 2025/5/1.
//

import SwiftUI

struct ScreenshotView: View {
    @ObservedObject private var appState = AppState.shared
    
    var body: some View {
        VStack {
            if let image = appState.screenshotImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("试着截一张图吧")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ScreenshotView()
}
