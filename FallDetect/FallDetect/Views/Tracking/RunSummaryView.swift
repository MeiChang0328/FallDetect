//
//  RunSummaryView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use SwiftData on 2025/12/16
//

import SwiftUI
import SwiftData
import CoreLocation

struct RunSummaryView: View {
    let tracker: RunTracker
    let location: CLLocation?
    let fallEvents: [FallDetection.FallEventData]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var averagePace: Double {
        guard tracker.elapsedTime > 0 else { return 0 }
        return Double(tracker.stepCount) / tracker.elapsedTime * 60.0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 漸變背景
                LinearGradient(
                    colors: [Color.appBackground, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 標題
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.appSuccess, .appPrimary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("跑步總結")
                                .font(.appTitle1)
                                .foregroundColor(.appTextPrimary)
                        }
                        .padding(.top, 20)
                        
                        // 統計數據卡片網格
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                StatCard(
                                    icon: "clock.fill",
                                    title: "跑步時間",
                                    value: formatTime(tracker.elapsedTime),
                                    color: .appPrimary,
                                    style: .expanded
                                )
                                
                                StatCard(
                                    icon: "figure.walk",
                                    title: "總步數",
                                    value: "\(tracker.stepCount)",
                                    unit: "步",
                                    color: .appSuccess,
                                    style: .expanded
                                )
                            }
                            
                            StatCard(
                                icon: "gauge",
                                title: "平均步頻",
                                value: "\(Int(averagePace))",
                                unit: "步/分鐘",
                                color: .appSecondary,
                                style: .expanded
                            )
                            
                            if let location = location {
                                StatCard(
                                    icon: "location.fill",
                                    title: "位置",
                                    value: formatLocation(location),
                                    color: .appWarning,
                                    style: .expanded
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // 跌倒事件警告（如果有）
                        if !fallEvents.isEmpty {
                            fallEventsSection
                        }
                        
                        Spacer()
                        
                        // 按鈕組
                        buttonSection
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Sections
    
    private var fallEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.appBody)
                    .foregroundColor(.appDanger)
                Text("跌倒偵測警告")
                    .font(.appTitle3)
                    .foregroundColor(.appDanger)
            }
            
            Text("本次跑步偵測到 \(fallEvents.count) 次可能的跌倒事件")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
            
            // 跌倒事件列表
            VStack(spacing: 10) {
                ForEach(fallEvents.indices, id: \.self) { index in
                    FallEventSummaryCard(event: fallEvents[index], index: index + 1)
                }
            }
        }
        .padding()
        .background(Color.appDanger.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appDanger.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal)
    }
    
    private var buttonSection: some View {
        VStack(spacing: 14) {
            // 保存按鈕
            Button(action: saveAndFinish) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.appTitle3)
                    Text("完成並保存")
                        .font(.appTitle3)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.appSuccess, .appPrimary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.appSuccess.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            
            // 捨棄按鈕
            Button(action: discardAndClose) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.appBody)
                    Text("捨棄記錄")
                        .font(.appBody)
                }
                .foregroundColor(.appDanger)
                .padding(.vertical, 10)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func saveAndFinish() {
        // 創建 RunRecord
        let record = RunRecord(
            date: Date(),
            duration: tracker.elapsedTime,
            stepCount: tracker.stepCount,
            averageCadence: averagePace,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude
        )
        modelContext.insert(record)
        
        // 創建關聯的 FallEvent（如果有）
        for eventData in fallEvents {
            let fallEvent = FallEvent(
                timestamp: eventData.timestamp,
                confidence: eventData.confidence,
                maxImpact: eventData.maxImpact,
                hadRotation: eventData.hadRotation,
                maxAttitudeChange: eventData.maxAttitudeChange,
                latitude: eventData.latitude,
                longitude: eventData.longitude,
                emailSent: false // Email 會在另外的流程發送
            )
            fallEvent.runRecord = record
            modelContext.insert(fallEvent)
        }
        
        // 保存到 SwiftData
        do {
            try modelContext.save()
            print("✅ 跑步記錄已保存：\(record.stepCount) 步，\(fallEvents.count) 次跌倒事件")
        } catch {
            print("❌ 保存跑步記錄失敗: \(error.localizedDescription)")
        }
        
        tracker.reset()
        dismiss()
    }
    
    private func discardAndClose() {
        tracker.reset()
        dismiss()
    }
    
    // MARK: - Helpers
    
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
    
    private func formatLocation(_ location: CLLocation) -> String {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        return String(format: "%.6f, %.6f", latitude, longitude)
    }
}

// MARK: - Fall Event Summary Card

struct FallEventSummaryCard: View {
    let event: FallDetection.FallEventData
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 標題列
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "number")
                        .font(.system(size: 10))
                        .foregroundColor(.appDanger)
                    Text("事件 #\(index)")
                        .font(.appBodySecondary)
                        .foregroundColor(.appTextPrimary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                    Text(event.timestamp, style: .time)
                        .font(.appCaption2)
                        .foregroundColor(.appTextSecondary)
                }
            }
            
            // 數據指標
            HStack(spacing: 16) {
                // 信心度
                HStack(spacing: 6) {
                    Image(systemName: "gauge.medium")
                        .font(.system(size: 12))
                        .foregroundColor(.appPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(event.confidence * 100))%")
                            .font(.appNumberSmall)
                            .foregroundColor(.appTextPrimary)
                        Text("信心度")
                            .font(.system(size: 9))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                Divider()
                    .frame(height: 30)
                
                // 衝擊力
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 12))
                        .foregroundColor(.appWarning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.1fG", event.maxImpact))
                            .font(.appNumberSmall)
                            .foregroundColor(.appTextPrimary)
                        Text("衝擊力")
                            .font(.system(size: 9))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                if event.hadRotation {
                    Divider()
                        .frame(height: 30)
                    
                    // 旋轉標記
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(.appSecondary)
                        Text("旋轉")
                            .font(.appCaption)
                            .foregroundColor(.appTextPrimary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.appShadowLight, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Previews

#Preview("Normal Run") {
    let tracker = RunTracker()
    return RunSummaryView(
        tracker: tracker,
        location: CLLocation(latitude: 25.0330, longitude: 121.5654),
        fallEvents: []
    )
    .modelContainer(ModelContainer.preview)
}

#Preview("Run with Falls") {
    let tracker = RunTracker()
    let fallEvents = [
        FallDetection.FallEventData(
            timestamp: Date(),
            confidence: 0.85,
            maxImpact: 2.5,
            hadRotation: true,
            maxAttitudeChange: 1.2,
            detectionMode: .sensitive,
            latitude: 25.0330,
            longitude: 121.5654
        )
    ]
    return RunSummaryView(
        tracker: tracker,
        location: CLLocation(latitude: 25.0330, longitude: 121.5654),
        fallEvents: fallEvents
    )
    .modelContainer(ModelContainer.preview)
}
