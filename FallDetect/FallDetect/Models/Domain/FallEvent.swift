//
//  FallEvent.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/16.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class FallEvent {
    var id: UUID
    var timestamp: Date
    var confidence: Double          // 信心度（0.0 ~ 1.0）
    var maxImpact: Double           // 最大衝擊力（G）
    var hadRotation: Bool           // 是否有旋轉
    var maxAttitudeChange: Double   // 最大姿態變化（弧度）
    var latitude: Double?
    var longitude: Double?
    var emailSent: Bool             // 是否已發送 Email
    var emailSentAt: Date?          // Email 發送時間
    var emailError: String?         // Email 發送錯誤訊息（如果有）
    
    // 關聯到跑步記錄（多對一）
    var runRecord: RunRecord?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        confidence: Double,
        maxImpact: Double,
        hadRotation: Bool,
        maxAttitudeChange: Double = 0.0,
        latitude: Double? = nil,
        longitude: Double? = nil,
        emailSent: Bool = false,
        emailSentAt: Date? = nil,
        emailError: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.confidence = confidence
        self.maxImpact = maxImpact
        self.hadRotation = hadRotation
        self.maxAttitudeChange = maxAttitudeChange
        self.latitude = latitude
        self.longitude = longitude
        self.emailSent = emailSent
        self.emailSentAt = emailSentAt
        self.emailError = emailError
    }
    
    // MARK: - Computed Properties
    
    /// 轉換為 CLLocation 物件（若有座標）
    var location: CLLocation? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    /// 格式化時間顯示
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: timestamp)
    }
    
    /// 信心度百分比字串
    var confidencePercentage: String {
        return String(format: "%.0f%%", confidence * 100)
    }
    
    /// 信心度等級描述
    var confidenceLevel: String {
        switch confidence {
        case 0.8...1.0:
            return "非常高"
        case 0.6..<0.8:
            return "高"
        case 0.4..<0.6:
            return "中等"
        case 0.2..<0.4:
            return "低"
        default:
            return "非常低"
        }
    }
    
    /// 最大衝擊力顯示
    var maxImpactString: String {
        return String(format: "%.2f G", maxImpact)
    }
    
    /// 位置字串
    var locationString: String {
        guard let lat = latitude, let lon = longitude else {
            return "無位置資訊"
        }
        return String(format: "%.6f, %.6f", lat, lon)
    }
    
    /// Google Maps 連結
    var googleMapsURL: URL? {
        guard let lat = latitude, let lon = longitude else { return nil }
        let urlString = "https://www.google.com/maps?q=\(lat),\(lon)"
        return URL(string: urlString)
    }
    
    /// Email 狀態描述
    var emailStatus: String {
        if emailSent {
            if let sentAt = emailSentAt {
                let formatter = DateFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .short
                return "已發送於 \(formatter.string(from: sentAt))"
            }
            return "已發送"
        } else if let error = emailError {
            return "發送失敗：\(error)"
        } else {
            return "未發送"
        }
    }
    
    /// 相對時間描述（例如：「5分鐘前」）
    var relativeTimeString: String {
        let interval = Date().timeIntervalSince(timestamp)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if days > 0 {
            return "\(days) 天前"
        } else if hours > 0 {
            return "\(hours) 小時前"
        } else if minutes > 0 {
            return "\(minutes) 分鐘前"
        } else {
            return "剛才"
        }
    }
}
