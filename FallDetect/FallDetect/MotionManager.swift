//
//  MotionManager.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var acceleration: CMAcceleration = CMAcceleration(x: 0, y: 0, z: 0)
    @Published var rotationRate: CMRotationRate = CMRotationRate(x: 0, y: 0, z: 0)
    @Published var attitude: CMAttitude?
    
    var isAvailable: Bool {
        return motionManager.isAccelerometerAvailable && motionManager.isGyroAvailable
    }
    
    func startUpdates() {
        guard isAvailable else {
            print("感測器不可用")
            return
        }
        
        // 設定更新頻率（每秒 10 次）
        motionManager.accelerometerUpdateInterval = 0.5
        motionManager.gyroUpdateInterval = 0.5
        
        // 開始加速度計更新
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                self.acceleration = data.acceleration
            }
        }
        
        // 開始陀螺儀更新
        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                self.rotationRate = data.rotationRate
            }
        }
        
        // 開始設備運動更新（包含姿態）
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                self.attitude = data.attitude
            }
        }
    }
    
    func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
    }
    
    // 計算總加速度（用於跌倒偵測）
    var totalAcceleration: Double {
        return sqrt(acceleration.x * acceleration.x + 
                    acceleration.y * acceleration.y + 
                    acceleration.z * acceleration.z)
    }
}

