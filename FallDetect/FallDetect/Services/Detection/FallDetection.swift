//
//  FallDetection.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use @Observable and enhanced algorithm on 2025/12/16
//

import Foundation
import CoreMotion
import Observation
import SwiftData

// MARK: - Detection Thresholds

/// 三種偵測模式的閾值配置
struct DetectionThresholds {
    let impactThreshold: Double          // G - 衝擊加速度閾值
    let freefallThreshold: Double        // G - 自由落體閾值
    let freefallDuration: TimeInterval   // 秒 - 自由落體最小持續時間
    let postImpactThreshold: Double      // G - 衝擊後靜止閾值
    let postImpactDuration: TimeInterval // 秒 - 靜止判定時間
    let rotationThreshold: Double        // rad/s - 角速度閾值
    let attitudeChangeThreshold: Double  // radians - 姿態變化閾值
    
    /// 保守模式：適合日常活動，避免誤報
    static let conservative = DetectionThresholds(
        impactThreshold: 2.5,
        freefallThreshold: 0.3,
        freefallDuration: 0.15,
        postImpactThreshold: 0.2,
        postImpactDuration: 1.0,
        rotationThreshold: 2.0,
        attitudeChangeThreshold: 1.0 // ~57度
    )
    
    /// 平衡模式：標準設定
    static let balanced = DetectionThresholds(
        impactThreshold: 1.8,
        freefallThreshold: 0.2,
        freefallDuration: 0.1,
        postImpactThreshold: 0.15,
        postImpactDuration: 0.6,
        rotationThreshold: 1.5,
        attitudeChangeThreshold: 0.8 // ~46度
    )
    
    /// 敏感模式：超高靈敏度，容易觸發（用於高風險場景）
    static let sensitive = DetectionThresholds(
        impactThreshold: 0.5,        // 0.5G 極低衝擊閾值
        freefallThreshold: 0.05,     // 幾乎任何下降都會觸發
        freefallDuration: 0.05,      // 50ms 極短自由落體
        postImpactThreshold: 0.05,   // 幾乎完全靜止
        postImpactDuration: 0.3,     // 快速判定
        rotationThreshold: 0.3,      // 微小轉動即觸發
        attitudeChangeThreshold: 0.5 // ~29度，極敏感
    )
    
    static func thresholds(for mode: DetectionMode) -> DetectionThresholds {
        switch mode {
        case .conservative: return .conservative
        case .balanced: return .balanced
        case .sensitive: return .sensitive
        }
    }
}

// MARK: - Fall Detection Engine

@Observable
final class FallDetection {
    var isFallDetected = false
    var fallConfidence: Double = 0.0
    var currentMode: DetectionMode = .balanced
    
    var onFallDetected: ((FallEventData) -> Void)?
    
    private var thresholds: DetectionThresholds {
        DetectionThresholds.thresholds(for: currentMode)
    }
    
    // 四階段跌倒偵測狀態機
    private enum FallPhase {
        case normal        // 正常狀態
        case freefall      // 自由落體階段
        case impact        // 衝擊階段
        case postImpact    // 衝擊後靜止階段
    }
    
    private var currentPhase: FallPhase = .normal
    private var freefallStartTime: Date?
    private var impactTime: Date?
    private var maxImpactMagnitude: Double = 0.0
    private var hasRotation: Bool = false
    private var maxAttitudeChange: Double = 0.0
    private var initialAttitude: CMAttitude?
    
    // 累積信心度系統（多次檢測累加）
    private var cumulativeConfidence: Double = 0.0
    private var confidenceHistory: [(timestamp: Date, value: Double)] = []
    private let confidenceWindowDuration: TimeInterval = 2.0 // 2秒內累積
    
    // 數據緩衝區（用於更準確的分析）
    private var accelerationBuffer: [CMAcceleration] = []
    private var rotationBuffer: [CMRotationRate] = []
    private let bufferSize = 10
    
    // 冷卻時間（避免重複偵測同一次跌倒）
    private var lastFallTime: Date?
    private let cooldownPeriod: TimeInterval = 5.0
    
    // 事件數據（用於記錄）
    struct FallEventData {
        let timestamp: Date
        let confidence: Double
        let maxImpact: Double
        let hadRotation: Bool
        let maxAttitudeChange: Double
        let detectionMode: DetectionMode
        let latitude: Double?
        let longitude: Double?
    }
    
    init(mode: DetectionMode = .balanced) {
        self.currentMode = mode
    }
    
    func updateMode(_ mode: DetectionMode) {
        self.currentMode = mode
        reset() // 切換模式時重置狀態
    }
    
    func analyzeMotion(
        acceleration: CMAcceleration,
        rotationRate: CMRotationRate,
        attitude: CMAttitude?,
        location: (latitude: Double, longitude: Double)? = nil
    ) {
        // 檢查冷卻期
        if let lastFall = lastFallTime, Date().timeIntervalSince(lastFall) < cooldownPeriod {
            return
        }
        
        // 更新數據緩衝區
        updateBuffers(acceleration: acceleration, rotation: rotationRate)
        
        // 計算總加速度（向量長度，單位：G）
        let totalAcceleration = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        
        // 計算總角速度（向量長度，單位：rad/s）
        let totalRotation = sqrt(
            rotationRate.x * rotationRate.x +
            rotationRate.y * rotationRate.y +
            rotationRate.z * rotationRate.z
        )
        
        // 追蹤姿態變化
        if let currentAttitude = attitude {
            if initialAttitude == nil {
                initialAttitude = currentAttitude.copy() as? CMAttitude
            } else if let initial = initialAttitude {
                currentAttitude.multiply(byInverseOf: initial)
                let attitudeChange = sqrt(
                    currentAttitude.pitch * currentAttitude.pitch +
                    currentAttitude.roll * currentAttitude.roll +
                    currentAttitude.yaw * currentAttitude.yaw
                )
                if attitudeChange > maxAttitudeChange {
                    maxAttitudeChange = attitudeChange
                }
            }
        }
        
        // 檢測是否有劇烈旋轉
        if totalRotation > thresholds.rotationThreshold {
            hasRotation = true
        }
        
        // 狀態機邏輯 - 四階段跌倒偵測
        switch currentPhase {
        case .normal:
            // 階段1：偵測自由落體（加速度突然降低）
            if totalAcceleration < thresholds.freefallThreshold {
                currentPhase = .freefall
                freefallStartTime = Date()
                maxImpactMagnitude = 0.0
                hasRotation = false
                maxAttitudeChange = 0.0
                initialAttitude = attitude?.copy() as? CMAttitude
                print("📉 [\(currentMode.displayName)] 偵測到自由落體: \(String(format: "%.2f", totalAcceleration))G")
            }
            // 或直接偵測到高衝擊（跳過自由落體階段）
            else if totalAcceleration > thresholds.impactThreshold {
                currentPhase = .impact
                impactTime = Date()
                maxImpactMagnitude = totalAcceleration
                initialAttitude = attitude?.copy() as? CMAttitude
                print("💥 [\(currentMode.displayName)] 偵測到直接衝擊: \(String(format: "%.2f", totalAcceleration))G")
            }
            
        case .freefall:
            // 階段2：持續監測自由落體
            if totalAcceleration < thresholds.freefallThreshold {
                // 繼續自由落體狀態
                if let startTime = freefallStartTime,
                   Date().timeIntervalSince(startTime) >= thresholds.freefallDuration {
                    // 自由落體時間足夠，等待衝擊
                    print("⏱️ 自由落體持續: \(String(format: "%.1f", Date().timeIntervalSince(startTime) * 1000))ms")
                }
            }
            // 偵測到衝擊
            else if totalAcceleration > thresholds.impactThreshold {
                currentPhase = .impact
                impactTime = Date()
                maxImpactMagnitude = totalAcceleration
                print("💥 自由落體後衝擊: \(String(format: "%.2f", totalAcceleration))G")
            }
            // 自由落體中斷但未達到衝擊閾值
            else {
                print("❌ 自由落體中斷，重置")
                resetDetection()
            }
            
        case .impact:
            // 階段3：記錄最大衝擊值
            if totalAcceleration > maxImpactMagnitude {
                maxImpactMagnitude = totalAcceleration
                print("📈 更新最大衝擊: \(String(format: "%.2f", maxImpactMagnitude))G")
            }
            
            // 衝擊後轉為靜止檢測
            if totalAcceleration < thresholds.postImpactThreshold {
                currentPhase = .postImpact
                print("🛑 進入靜止檢測階段")
            }
            
        case .postImpact:
            // 階段4：檢查衝擊後是否保持靜止
            if totalAcceleration < thresholds.postImpactThreshold {
                if let impact = impactTime,
                   Date().timeIntervalSince(impact) >= thresholds.postImpactDuration {
                    // 確認跌倒！
                    confirmFall(location: location)
                }
            }
            // 如果突然有大動作，可能正在恢復
            else if totalAcceleration > 0.7 {
                // 但如果已經有足夠證據，還是算跌倒
                if let impact = impactTime,
                   Date().timeIntervalSince(impact) >= (thresholds.postImpactDuration * 0.5),
                   maxImpactMagnitude > thresholds.impactThreshold * 1.2 {
                    confirmFall(location: location)
                } else {
                    print("↗️ 恢復動作，取消跌倒判定")
                    resetDetection()
                }
            }
        }
        
        // 持續更新信心度（累積系統）
        updateConfidence(totalAcceleration: totalAcceleration, totalRotation: totalRotation)
    }
    
    private func updateBuffers(acceleration: CMAcceleration, rotation: CMRotationRate) {
        accelerationBuffer.append(acceleration)
        rotationBuffer.append(rotation)
        
        if accelerationBuffer.count > bufferSize {
            accelerationBuffer.removeFirst()
        }
        if rotationBuffer.count > bufferSize {
            rotationBuffer.removeFirst()
        }
    }
    
    private func updateConfidence(totalAcceleration: Double, totalRotation: Double) {
        var instantConfidence: Double = 0.0
        
        switch currentPhase {
        case .normal:
            instantConfidence = 0.0
            
        case .freefall:
            // 自由落體階段信心度 20-40%
            if let startTime = freefallStartTime {
                let duration = Date().timeIntervalSince(startTime)
                instantConfidence = min(0.4, 0.2 + duration * 0.5)
            }
            
        case .impact:
            // 衝擊階段信心度 40-70%
            let impactFactor = min(1.0, (maxImpactMagnitude - thresholds.impactThreshold) / thresholds.impactThreshold)
            instantConfidence = 0.4 + impactFactor * 0.3
            
            // 如果有旋轉，增加信心度
            if hasRotation {
                instantConfidence += 0.1
            }
            
            // 如果有姿態變化，增加信心度
            if maxAttitudeChange > thresholds.attitudeChangeThreshold {
                instantConfidence += 0.05
            }
            
        case .postImpact:
            // 衝擊後靜止階段信心度 70-95%
            if let impact = impactTime {
                let stillDuration = Date().timeIntervalSince(impact)
                let impactFactor = min(1.0, (maxImpactMagnitude - thresholds.impactThreshold) / thresholds.impactThreshold)
                instantConfidence = 0.7 + stillDuration * 0.15 + impactFactor * 0.1
                
                // 如果有旋轉，增加信心度
                if hasRotation {
                    instantConfidence += 0.05
                }
                
                // 如果有明顯姿態變化（倒地），大幅增加信心度
                if maxAttitudeChange > thresholds.attitudeChangeThreshold {
                    instantConfidence += 0.1
                }
                
                instantConfidence = min(0.95, instantConfidence)
            }
        }
        
        // 累積信心度系統
        let now = Date()
        confidenceHistory.append((timestamp: now, value: instantConfidence))
        
        // 移除超過時間窗口的歷史記錄
        confidenceHistory.removeAll { now.timeIntervalSince($0.timestamp) > confidenceWindowDuration }
        
        // 計算累積信心度（取最大值 + 平均值混合）
        if !confidenceHistory.isEmpty {
            let maxConfidence = confidenceHistory.map { $0.value }.max() ?? 0.0
            let avgConfidence = confidenceHistory.map { $0.value }.reduce(0.0, +) / Double(confidenceHistory.count)
            cumulativeConfidence = maxConfidence * 0.7 + avgConfidence * 0.3
        } else {
            cumulativeConfidence = 0.0
        }
        
        // 更新顯示的信心度
        fallConfidence = cumulativeConfidence
    }
    
    private func confirmFall(location: (latitude: Double, longitude: Double)?) {
        print("🚨🚨🚨 跌倒確認！🚨🚨🚨")
        print("  ├─ 偵測模式: \(currentMode.displayName)")
        print("  ├─ 最大衝擊: \(String(format: "%.2f", maxImpactMagnitude))G")
        print("  ├─ 有旋轉: \(hasRotation ? "是" : "否")")
        print("  ├─ 姿態變化: \(String(format: "%.2f", maxAttitudeChange * 180 / .pi))°")
        print("  └─ 信心度: \(String(format: "%.1f", fallConfidence * 100))%")
        
        let eventData = FallEventData(
            timestamp: Date(),
            confidence: fallConfidence,
            maxImpact: maxImpactMagnitude,
            hadRotation: hasRotation,
            maxAttitudeChange: maxAttitudeChange,
            detectionMode: currentMode,
            latitude: location?.latitude,
            longitude: location?.longitude
        )
        
        isFallDetected = true
        onFallDetected?(eventData)
        
        lastFallTime = Date()
        resetDetection()
    }
    
    private func resetDetection() {
        currentPhase = .normal
        freefallStartTime = nil
        impactTime = nil
        maxImpactMagnitude = 0.0
        hasRotation = false
        maxAttitudeChange = 0.0
        initialAttitude = nil
        confidenceHistory.removeAll()
        cumulativeConfidence = 0.0
    }
    
    func reset() {
        isFallDetected = false
        fallConfidence = 0.0
        resetDetection()
        accelerationBuffer.removeAll()
        rotationBuffer.removeAll()
    }
    
    // 手動觸發跌倒偵測（用於測試）
    func triggerTestFall(location: (latitude: Double, longitude: Double)? = nil) {
        print("🧪 手動觸發測試跌倒 [\(currentMode.displayName)]")
        maxImpactMagnitude = 3.0
        hasRotation = true
        maxAttitudeChange = 1.2
        fallConfidence = 0.92
        confirmFall(location: location)
    }
}
