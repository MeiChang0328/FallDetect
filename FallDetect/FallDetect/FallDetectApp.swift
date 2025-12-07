//
//  FallDetectApp.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import SwiftUI

@main
struct FallDetectApp: App {
    @StateObject private var recordStore = RunRecordStore()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                RunTrackingView(recordStore: recordStore)
                    .tabItem {
                        Label("跑步", systemImage: "figure.run")
                    }
                
                HistoryView(recordStore: recordStore)
                    .tabItem {
                        Label("記錄", systemImage: "clock.arrow.circlepath")
                    }
            }
        }
    }
}
