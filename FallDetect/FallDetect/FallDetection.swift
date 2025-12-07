//
//  FallDetection.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import Foundation
import CoreMotion
import Combine

class FallDetection: ObservableObject {
    @Published var isFallDetected = false
    @Published var fallConfidence: Double = 0.0 // 0.0 - 1.0
    
    // 跌倒偵測閾值
    private let accelerationThreshold: Double = 2.5 // g 值（重力加速度的倍數）
    private let rotationThreshold: Double = 2.0 // rad/s
    private let attitudeChangeThreshold: Double = 0.7 // 姿態變化閾值（約 45 度）
    
    // 用於平滑數據的緩衝區
    private var accelerationBuffer: [Double] = []
    private let bufferSize = 5
    
    // 防止重複觸發的計時器
    private var lastFallTime: Date?
    private let fallCooldown: TimeInterval = 3.0 // 3秒內不重複觸發
    
    func analyzeMotion(acceleration: CMAcceleration, rotationRate: CMRotationRate, attitude: CMAttitude?) {
        // 計算總加速度（減去重力）
        let totalAcceleration = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        
        // 計算總角速度
        let totalRotation = sqrt(
            rotationRate.x * rotationRate.x +
            rotationRate.y * rotationRate.y +
            rotationRate.z * rotationRate.z
        )
        
        // 將加速度加入緩衝區
        accelerationBuffer.append(totalAcceleration)
        if accelerationBuffer.count > bufferSize {
            accelerationBuffer.removeFirst()
        }
        
        // 計算平均加速度（平滑處理）
        let averageAcceleration = accelerationBuffer.reduce(0, +) / Double(accelerationBuffer.count)
        
        // 檢查是否在冷卻期內
        if let lastFall = lastFallTime, Date().timeIntervalSince(lastFall) < fallCooldown {
            return
        }
        
        // 跌倒偵測邏輯
        var confidence: Double = 0.0
        
        // 1. 加速度突變檢測（超過閾值）
        if averageAcceleration > accelerationThreshold {
            let accelerationScore = min(1.0, (averageAcceleration - accelerationThreshold) / 2.0)
            confidence += accelerationScore * 0.5
        }
        
        // 2. 角速度突變檢測（快速旋轉）
        if totalRotation > rotationThreshold {
            let rotationScore = min(1.0, (totalRotation - rotationThreshold) / 2.0)
            confidence += rotationScore * 0.3
        }
        
        // 3. 姿態變化檢測（設備從垂直變為水平）
        if let attitude = attitude {
            // 計算 pitch 和 roll 的變化（設備傾斜）
            let pitch = abs(attitude.pitch)
            let roll = abs(attitude.roll)
            let maxTilt = max(pitch, roll)
            
            if maxTilt > attitudeChangeThreshold {
                let attitudeScore = min(1.0, (maxTilt - attitudeChangeThreshold) / 0.5)
                confidence += attitudeScore * 0.2
            }
        }
        
        // 更新信心度
        fallConfidence = min(1.0, confidence)
        
        // 如果信心度超過 0.6，判定為跌倒
        if confidence > 0.6 && !isFallDetected {
            isFallDetected = true
            lastFallTime = Date()
            
            // 觸發跌倒事件
            onFallDetected()
        } else if confidence < 0.3 {
            // 如果信心度降低，重置狀態
            isFallDetected = false
        }
    }
    
    // 跌倒事件回調
    var onFallDetected: () -> Void = {}
    
    func reset() {
        isFallDetected = false
        fallConfidence = 0.0
        accelerationBuffer.removeAll()
        lastFallTime = nil
    }
}

