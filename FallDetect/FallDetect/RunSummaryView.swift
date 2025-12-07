//
//  RunSummaryView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import SwiftUI

struct RunSummaryView: View {
    @ObservedObject var tracker: RunTracker
    @Environment(\.dismiss) var dismiss
    
    var averageCadence: Double {
        guard tracker.elapsedTime > 0 else { return 0 }
        return Double(tracker.stepCount) / tracker.elapsedTime * 60.0
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("跑步總結")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 20) {
                    SummaryRow(title: "跑步時間", value: formatTime(tracker.elapsedTime))
                    SummaryRow(title: "總步數", value: "\(tracker.stepCount) 步")
                    SummaryRow(title: "平均步頻", value: "\(Int(averageCadence)) 步/分鐘")
                }
                .padding()
                
                Spacer()
                
                Button(action: {
                    tracker.reset()
                    dismiss()
                }) {
                    Text("完成")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        tracker.reset()
                        dismiss()
                    }
                }
            }
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

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    RunSummaryView(tracker: RunTracker())
}

