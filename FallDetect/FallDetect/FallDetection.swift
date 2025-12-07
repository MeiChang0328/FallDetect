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

    // Gravity estimation for linear acceleration (低通濾波器)
    private var gravity: (x: Double, y: Double, z: Double) = (0, 0, 0)
    private let gravityAlpha: Double = 0.8 // 0..1, 越接近1表示對新數據反應越慢

    // State machine for more robust detection
    private enum State {
        case idle
        case possibleImpact
        case possibleFall
        case fallen
    }
    private var state: State = .idle

    // Sensitivity tuning (公開供 Settings 使用)
    var sensitivity: Double = 1.0 { // 0.5 (less sensitive) .. 2.0 (more sensitive)
        didSet {
            sensitivity = max(0.5, min(2.0, sensitivity))
        }
    }

    // Timers for state transitions
    private var impactDetectedAt: Date?
    private var freeFallDetectedAt: Date?
    private var inactivityDetectedAt: Date?
    
    func analyzeMotion(acceleration: CMAcceleration, rotationRate: CMRotationRate, attitude: CMAttitude?) {
        // 1) 計算總加速度與角速度
        let rawTotalAcceleration = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        let totalRotation = sqrt(
            rotationRate.x * rotationRate.x +
            rotationRate.y * rotationRate.y +
            rotationRate.z * rotationRate.z
        )

        // 2) 重力估計（低通濾波）與線性加速度（高通）
        gravity.x = gravityAlpha * gravity.x + (1 - gravityAlpha) * acceleration.x
        gravity.y = gravityAlpha * gravity.y + (1 - gravityAlpha) * acceleration.y
        gravity.z = gravityAlpha * gravity.z + (1 - gravityAlpha) * acceleration.z

        let linearX = acceleration.x - gravity.x
        let linearY = acceleration.y - gravity.y
        let linearZ = acceleration.z - gravity.z
        let linearAcceleration = sqrt(linearX * linearX + linearY * linearY + linearZ * linearZ)

        // 3) 低延遲緩衝與短期平均（更平滑的瞬時影響檢測）
        accelerationBuffer.append(linearAcceleration)
        if accelerationBuffer.count > bufferSize {
            accelerationBuffer.removeFirst()
        }
        let avgLinearAcc = accelerationBuffer.reduce(0, +) / Double(accelerationBuffer.count)

        // 4) 早退出：冷卻期
        if let lastFall = lastFallTime, Date().timeIntervalSince(lastFall) < fallCooldown {
            // 仍更新 internal gravity/ buffers but 不再次觸發
            fallConfidence = max(0.0, fallConfidence - 0.05) // 緩慢下降信心
            return
        }

        // 5) 特徵評分
        // impactScore: 瞬時高線性加速度
        let impactThreshold = accelerationThreshold * sensitivity
        var impactScore = 0.0
        if avgLinearAcc > impactThreshold {
            impactScore = min(1.0, (avgLinearAcc - impactThreshold) / (impactThreshold))
        }

        // freeFallScore: 接近自由落體（總加速度接近 0g）
        var freeFallScore = 0.0
        if rawTotalAcceleration < 0.6 { // <0.6g 視為短暫失重
            freeFallScore = min(1.0, (0.6 - rawTotalAcceleration) / 0.6)
        }

        // rotationScore: 快速旋轉
        let rotationThresholdAdj = rotationThreshold * sensitivity
        var rotationScore = 0.0
        if totalRotation > rotationThresholdAdj {
            rotationScore = min(1.0, (totalRotation - rotationThresholdAdj) / rotationThresholdAdj)
        }

        // orientationScore: 設備由直立到水平（若提供姿態）
        var orientationScore = 0.0
        if let attitude = attitude {
            let pitch = abs(attitude.pitch)
            let roll = abs(attitude.roll)
            let maxTilt = max(pitch, roll)
            if maxTilt > attitudeChangeThreshold {
                orientationScore = min(1.0, (maxTilt - attitudeChangeThreshold) / 1.0)
            }
        }

        // inactivityScore: 撞擊後長時間靜止（可透過外部定期檢查速度/位置變化來加強）
        var inactivityScore = 0.0
        if isFallDetected {
            // 若已偵測並維持靜止一段時間，增加信心
            if inactivityDetectedAt == nil {
                inactivityDetectedAt = Date()
            } else if let t = inactivityDetectedAt, Date().timeIntervalSince(t) > 4.0 {
                inactivityScore = 1.0
            }
        } else {
            inactivityDetectedAt = nil
        }

        // 6) 綜合信心：加權組合（impact 為主要因素）
        // 權重可調整以改進精確度
        let confidence = min(1.0,
                             impactScore * 0.5 +
                             freeFallScore * 0.25 +
                             rotationScore * 0.15 +
                             orientationScore * 0.08 +
                             inactivityScore * 0.2)

        // 7) 狀態機：更穩健地決定跌倒發生
        switch state {
        case .idle:
            if impactScore > 0.4 {
                state = .possibleImpact
                impactDetectedAt = Date()
            } else if freeFallScore > 0.6 {
                state = .possibleFall
                freeFallDetectedAt = Date()
            }
        case .possibleImpact:
            // 如果在短時間內觀察到 freefall 或高轉速，加強判定
            if Date().timeIntervalSince(impactDetectedAt ?? Date()) > 2.0 {
                state = .idle
                impactDetectedAt = nil
            } else if freeFallScore > 0.3 || rotationScore > 0.4 || orientationScore > 0.3 {
                state = .fallen
            }
        case .possibleFall:
            if Date().timeIntervalSince(freeFallDetectedAt ?? Date()) > 2.0 {
                state = .idle
                freeFallDetectedAt = nil
            } else if impactScore > 0.3 || rotationScore > 0.4 {
                state = .fallen
            }
        case .fallen:
            // 保持 fallen 直到信心大幅下降或手動重置
            break
        }

        // 8) 更新公開狀態和回調
        fallConfidence = confidence

        if state == .fallen && confidence > 0.5 && !isFallDetected {
            isFallDetected = true
            lastFallTime = Date()
            // 設定靜止監測的起點
            inactivityDetectedAt = Date()
            onFallDetected()
        } else if confidence < 0.25 {
            // 只有在低信心時才回到 idle
            isFallDetected = false
            fallConfidence = max(0.0, fallConfidence - 0.1)
            if state != .idle { state = .idle }
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

