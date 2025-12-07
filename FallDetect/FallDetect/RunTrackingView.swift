//
//  RunTrackingView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import SwiftUI

struct RunTrackingView: View {
    @StateObject private var tracker = RunTracker()
    @State private var showSummary = false
    
    var body: some View {
        VStack(spacing: 30) {
            // 時間顯示
            VStack(spacing: 10) {
                Text("跑步時間")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(formatTime(tracker.elapsedTime))
                    .font(.system(size: 48, weight: .bold))
            }
            .padding()
            
            // 步數顯示
            VStack(spacing: 10) {
                Text("步數")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("\(tracker.stepCount)")
                    .font(.system(size: 36, weight: .semibold))
            }
            .padding()
            
            // 步頻顯示
            VStack(spacing: 10) {
                Text("每分鐘步頻")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("\(Int(tracker.cadence)) 步/分鐘")
                    .font(.system(size: 24, weight: .medium))
            }
            .padding()
            
            Spacer()
            
            // 開始/停止按鈕
            Button(action: {
                if tracker.isRunning {
                    tracker.stop()
                    showSummary = true
                } else {
                    tracker.start()
                }
            }) {
                Text(tracker.isRunning ? "停止" : "開始")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(tracker.isRunning ? Color.red : Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showSummary) {
            RunSummaryView(tracker: tracker)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    RunTrackingView()
}

