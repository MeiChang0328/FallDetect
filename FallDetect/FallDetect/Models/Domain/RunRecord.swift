//
//  RunRecord.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/16.
//  Refactored to use SwiftData
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class RunRecord {
    var id: UUID
    var date: Date
    var duration: TimeInterval
    var stepCount: Int
    var averageCadence: Double
    var latitude: Double?
    var longitude: Double?
    
    // 關聯到跌倒事件（一對多）
    @Relationship(deleteRule: .cascade, inverse: \FallEvent.runRecord)
    var fallEvents: [FallEvent]?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval,
        stepCount: Int,
        averageCadence: Double,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.stepCount = stepCount
        self.averageCadence = averageCadence
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // MARK: - Computed Properties
    
    /// 轉換為 CLLocation 物件（若有座標）
    var location: CLLocation? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    /// 格式化時間顯示
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// 格式化日期顯示
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
    
    // MARK: - Convenience Methods
    
    /// 取得位置字串（用於顯示）
    var locationString: String {
        guard let lat = latitude, let lon = longitude else {
            return "無位置資訊"
        }
        return String(format: "%.6f, %.6f", lat, lon)
    }
    
    /// 計算配速（分鐘/公里，估算）
    var estimatedPacePerKm: Double? {
        // 假設步頻 × 時間 × 步長(0.7m) = 距離
        let distance = Double(stepCount) * 0.7 / 1000.0 // 公里
        guard distance > 0 else { return nil }
        return duration / 60.0 / distance // 分鐘/公里
    }
    
    /// 估算距離（公里）
    var estimatedDistance: Double {
        return Double(stepCount) * 0.7 / 1000.0
    }
    
    /// Google Maps 連結
    var googleMapsURL: URL {
        if let lat = latitude, let lon = longitude {
            let urlString = "https://www.google.com/maps?q=\(lat),\(lon)"
            return URL(string: urlString)!
        } else {
            // 如果沒有位置資訊，返回 Google Maps 首頁
            return URL(string: "https://www.google.com/maps")!
        }
    }
}
