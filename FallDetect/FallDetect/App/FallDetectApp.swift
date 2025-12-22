//
//  FallDetectApp.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use SwiftData on 2025/12/16
//

import SwiftUI
import SwiftData

@main
struct FallDetectApp: App {
    // SwiftData ModelContainer
    let modelContainer: ModelContainer
    
    init() {
        do {
            // 配置 Schema
            let schema = Schema([
                RunRecord.self,
                FallEvent.self,
                AppSettings.self
            ])
            
            // 配置 ModelConfiguration
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
                // 如需啟用 iCloud 同步，取消註解下行：
                // cloudKitDatabase: .automatic
            )
            
            // 建立 ModelContainer
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            // 初始化預設設定
            initializeDefaultSettings()
            
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                RunTrackingView()
                    .tabItem {
                        Label("跑步", systemImage: "figure.run")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("記錄", systemImage: "clock.arrow.circlepath")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("設定", systemImage: "gearshape")
                    }
            }
            .modelContainer(modelContainer)
        }
    }
    
    /// 初始化預設設定（如果不存在）
    private func initializeDefaultSettings() {
        let context = modelContainer.mainContext
        
        // 檢查是否已有設定
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let existingSettings = try context.fetch(descriptor)
            
            if let settings = existingSettings.first {
                // 設定已存在，更新共用實例
                AppSettings.shared = settings
                print("✅ 載入現有設定")
            } else {
                // 建立預設設定
                let defaultSettings = AppSettings()
                context.insert(defaultSettings)
                try context.save()
                AppSettings.shared = defaultSettings
                print("✅ 建立預設設定")
            }
        } catch {
            print("⚠️ 無法初始化設定：\(error.localizedDescription)")
            // 即使失敗也建立一個臨時設定
            AppSettings.shared = AppSettings()
        }
    }
}
