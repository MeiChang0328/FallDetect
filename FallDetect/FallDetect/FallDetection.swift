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
    @Published var fallConfidence: Double = 0.0
    
    var onFallDetected: (() -> Void)?
    
    // ============================================
    // 超靈敏跌倒偵測演算法（基於真實研究閾值）
    // ============================================
    
    // 超高靈敏度閾值設定（極易觸發）
    private let impactThreshold: Double = 0.5        // 0.5G 衝擊加速度（超靈敏！）
    private let freefallThreshold: Double = 0.05     // 0.05G 自由落體閾值（幾乎任何動作都會觸發）
    private let freefallDuration: TimeInterval = 0.05 // 50毫秒自由落體最小持續時間（極短）
    private let postImpactThreshold: Double = 0.05   // 衝擊後靜止閾值（幾乎完全靜止才算）
    private let postImpactDuration: TimeInterval = 0.3 // 0.3秒靜止判定時間（快速判定）
    private let rotationThreshold: Double = 0.3      // 角速度閾值 (rad/s)，偵測翻滾（微小轉動即觸發）
    
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
    
    // 數據緩衝區（用於更準確的分析）
    private var accelerationBuffer: [CMAcceleration] = []
    private var rotationBuffer: [CMRotationRate] = []
    private let bufferSize = 10
    
    // 冷卻時間（避免重複偵測同一次跌倒）
    private var lastFallTime: Date?
    private let cooldownPeriod: TimeInterval = 5.0
    
    func analyzeMotion(acceleration: CMAcceleration, rotationRate: CMRotationRate, attitude: CMAttitude) {
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
        
        // 檢測是否有劇烈旋轉
        if totalRotation > rotationThreshold {
            hasRotation = true
        }
        
        // 狀態機邏輯 - 四階段跌倒偵測
        switch currentPhase {
        case .normal:
            // 階段1：偵測自由落體（加速度突然降低）
            if totalAcceleration < freefallThreshold {
                currentPhase = .freefall
                freefallStartTime = Date()
                maxImpactMagnitude = 0.0
                hasRotation = false
                print("📉 偵測到自由落體: \(String(format: "%.2f", totalAcceleration))G")
            }
            // 或直接偵測到高衝擊（跳過自由落體階段）
            else if totalAcceleration > impactThreshold {
                currentPhase = .impact
                impactTime = Date()
                maxImpactMagnitude = totalAcceleration
                print("💥 偵測到直接衝擊: \(String(format: "%.2f", totalAcceleration))G")
            }
            
        case .freefall:
            // 階段2：持續監測自由落體
            if totalAcceleration < freefallThreshold {
                // 繼續自由落體狀態
                if let startTime = freefallStartTime,
                   Date().timeIntervalSince(startTime) >= freefallDuration {
                    // 自由落體時間足夠，等待衝擊
                    print("⏱️ 自由落體持續: \(String(format: "%.1f", Date().timeIntervalSince(startTime) * 1000))ms")
                }
            }
            // 偵測到衝擊
            else if totalAcceleration > impactThreshold {
                currentPhase = .impact
                impactTime = Date()
                maxImpactMagnitude = totalAcceleration
                print("💥 自由落體後衝擊: \(String(format: "%.2f", totalAcceleration))G")
            }
            // 自由落體中斷但未達到衝擊閾值（可能是誤判或動作調整）
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
            if totalAcceleration < postImpactThreshold {
                currentPhase = .postImpact
                print("🛑 進入靜止檢測階段")
            }
            
        case .postImpact:
            // 階段4：檢查衝擊後是否保持靜止
            if totalAcceleration < postImpactThreshold {
                if let impact = impactTime,
                   Date().timeIntervalSince(impact) >= postImpactDuration {
                    // 確認跌倒！
                    confirmFall()
                }
            }
            // 如果突然有大動作，可能正在恢復
            else if totalAcceleration > 0.7 {
                // 但如果已經有足夠證據（高衝擊+一定時間靜止），還是算跌倒
                if let impact = impactTime,
                   Date().timeIntervalSince(impact) >= 0.2,
                   maxImpactMagnitude > impactThreshold * 1.2 {
                    confirmFall()
                } else {
                    print("↗️ 恢復動作，取消跌倒判定")
                    resetDetection()
                }
            }
        }
        
        // 持續更新信心度
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
        var confidence: Double = 0.0
        
        switch currentPhase {
        case .normal:
            confidence = 0.0
            
        case .freefall:
            // 自由落體階段信心度 20-40%
            if let startTime = freefallStartTime {
                let duration = Date().timeIntervalSince(startTime)
                confidence = min(0.4, 0.2 + duration * 0.5)
            }
            
        case .impact:
            // 衝擊階段信心度 40-70%
            let impactFactor = min(1.0, (maxImpactMagnitude - impactThreshold) / impactThreshold)
            confidence = 0.4 + impactFactor * 0.3
            
            // 如果有旋轉，增加信心度
            if hasRotation {
                confidence += 0.1
            }
            
        case .postImpact:
            // 衝擊後靜止階段信心度 70-95%
            if let impact = impactTime {
                let stillDuration = Date().timeIntervalSince(impact)
                let impactFactor = min(1.0, (maxImpactMagnitude - impactThreshold) / impactThreshold)
                confidence = 0.7 + stillDuration * 0.15 + impactFactor * 0.1
                
                // 如果有旋轉，增加信心度
                if hasRotation {
                    confidence += 0.05
                }
                
                confidence = min(0.95, confidence)
            }
        }
        
        DispatchQueue.main.async {
            self.fallConfidence = confidence
        }
    }
    
    private func confirmFall() {
        print("🚨🚨🚨 跌倒確認！🚨🚨🚨")
        print("  ├─ 最大衝擊: \(String(format: "%.2f", maxImpactMagnitude))G")
        print("  ├─ 有旋轉: \(hasRotation ? "是" : "否")")
        print("  └─ 信心度: \(String(format: "%.1f", fallConfidence * 100))%")
        
        DispatchQueue.main.async {
            self.isFallDetected = true
            self.onFallDetected?()
        }
        
        lastFallTime = Date()
        resetDetection()
    }
    
    private func resetDetection() {
        currentPhase = .normal
        freefallStartTime = nil
        impactTime = nil
        maxImpactMagnitude = 0.0
        hasRotation = false
    }
    
    func reset() {
        DispatchQueue.main.async {
            self.isFallDetected = false
            self.fallConfidence = 0.0
        }
        resetDetection()
        accelerationBuffer.removeAll()
        rotationBuffer.removeAll()
    }
    
    // 手動觸發跌倒偵測（用於測試）
    func triggerTestFall() {
        print("🧪 手動觸發測試跌倒")
        maxImpactMagnitude = 3.0
        hasRotation = true
        confirmFall()
    }
}
