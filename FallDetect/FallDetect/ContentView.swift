//
//  ContentView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var fallDetection = FallDetection()
    @State private var showFallAlert = false

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("跌倒偵測測試")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("點擊下方按鈕來模擬一次跌倒事件。")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                fallDetection.triggerTestFall()
            }) {
                Text("觸發測試跌倒")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding()
        }
        .onReceive(fallDetection.$isFallDetected) { isDetected in
            if isDetected {
                showFallAlert = true
            }
        }
        .alert("偵測到跌倒", isPresented: $showFallAlert) {
            Button("好的", role: .cancel) {
                fallDetection.reset()
            }
        } message: {
            Text("已成功觸發模擬的跌倒事件。")
        }
    }
}

#Preview {
    ContentView()
}
