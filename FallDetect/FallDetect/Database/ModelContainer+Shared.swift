//
//  ModelContainer+Shared.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/16.
//

import Foundation
import SwiftData

extension ModelContainer {
    /// 共用的 ModelContainer 實例
    static var shared: ModelContainer = {
        let schema = Schema([
            RunRecord.self,
            FallEvent.self,
            AppSettings.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // 如需啟用 iCloud 同步，取消註解下行：
            // cloudKitDatabase: .automatic
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()
}
