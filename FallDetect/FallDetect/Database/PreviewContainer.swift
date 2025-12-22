//
//  PreviewContainer.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/16.
//

import Foundation
import SwiftData

/// Preview 專用的 ModelContainer，使用記憶體儲存並包含測試資料
@MainActor
class PreviewContainer {
    static let shared = PreviewContainer()
    
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            RunRecord.self,
            FallEvent.self,
            AppSettings.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true  // 僅存在記憶體中
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            // 插入測試資料
            insertSampleData()
        } catch {
            fatalError("Failed to create preview container: \(error.localizedDescription)")
        }
    }
    
    /// 插入範例測試資料
    private func insertSampleData() {
        let context = container.mainContext
        
        // 範例跑步記錄 1
        let record1 = RunRecord(
            date: Date().addingTimeInterval(-86400 * 2), // 2 天前
            duration: 1800, // 30 分鐘
            stepCount: 2500,
            averageCadence: 83.3,
            latitude: 25.0330,
            longitude: 121.5654
        )
        context.insert(record1)
        
        // 範例跑步記錄 2
        let record2 = RunRecord(
            date: Date().addingTimeInterval(-86400), // 1 天前
            duration: 2400, // 40 分鐘
            stepCount: 3200,
            averageCadence: 80.0,
            latitude: 25.0420,
            longitude: 121.5750
        )
        context.insert(record2)
        
        // 範例跑步記錄 3（今天）
        let record3 = RunRecord(
            date: Date().addingTimeInterval(-3600), // 1 小時前
            duration: 1500, // 25 分鐘
            stepCount: 2000,
            averageCadence: 80.0,
            latitude: 25.0350,
            longitude: 121.5680
        )
        context.insert(record3)
        
        // 範例跌倒事件（關聯到 record2）
        let fallEvent = FallEvent(
            timestamp: Date().addingTimeInterval(-86000),
            confidence: 0.85,
            maxImpact: 2.5,
            hadRotation: true,
            latitude: 25.0420,
            longitude: 121.5750,
            emailSent: true,
            emailSentAt: Date().addingTimeInterval(-85900)
        )
        fallEvent.runRecord = record2
        context.insert(fallEvent)
        
        // 範例設定
        let settings = AppSettings(
            isFallDetectionEnabled: true,
            fallDetectionMode: .sensitive,
            emergencyEmail: "test@example.com",
            enableEmailNotifications: true,
            hasSendGridAPIKey: true,
            senderEmail: "noreply@falldetect.app",
            senderName: "FallDetect 測試系統"
        )
        context.insert(settings)
        AppSettings.shared = settings
        
        // 儲存資料
        do {
            try context.save()
        } catch {
            print("Failed to save sample data: \(error)")
        }
    }
}

// MARK: - Preview Helper Extension

#if DEBUG
extension ModelContainer {
    /// 取得 Preview 用的 ModelContainer（含測試資料）
    static var preview: ModelContainer {
        PreviewContainer.shared.container
    }
    
    /// 取得空的 Preview ModelContainer（無資料）
    static var emptyPreview: ModelContainer {
        let schema = Schema([
            RunRecord.self,
            FallEvent.self,
            AppSettings.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create empty preview container: \(error.localizedDescription)")
        }
    }
}
#endif
