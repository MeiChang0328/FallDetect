//
//  RunRecord.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import Foundation
import CoreLocation

struct RunRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let stepCount: Int
    let averageCadence: Double
    let latitude: Double?
    let longitude: Double?
    
    var location: CLLocation? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         duration: TimeInterval,
         stepCount: Int,
         averageCadence: Double,
         location: CLLocation? = nil) {
        self.id = id
        self.date = date
        self.duration = duration
        self.stepCount = stepCount
        self.averageCadence = averageCadence
        self.latitude = location?.coordinate.latitude
        self.longitude = location?.coordinate.longitude
    }
    
    // 格式化時間
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
    
    // 格式化日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
}

