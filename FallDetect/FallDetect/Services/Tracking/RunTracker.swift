//
//  RunTracker.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use @Observable on 2025/12/16
//

import Foundation
import CoreMotion
import Observation

@Observable
final class RunTracker {
    var isRunning = false
    var elapsedTime: TimeInterval = 0
    var stepCount: Int = 0
    var cadence: Double = 0 // 每分鐘步頻
    
    private var timer: Timer?
    private let pedometer = CMPedometer()
    private var startDate: Date?
    private var startStepCount: Int = 0
    private var lastStepCount: Int = 0
    private var lastCadenceUpdate: Date = Date()
    
    init() {}
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        startDate = Date()
        elapsedTime = 0
        stepCount = 0
        cadence = 0
        lastStepCount = 0
        lastCadenceUpdate = Date()
        
        // 開始計時器
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startDate = self.startDate else { return }
            self.elapsedTime = Date().timeIntervalSince(startDate)
        }
        
        // 開始計步
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                
                // 使用 Task 在 MainActor 更新 UI
                Task { @MainActor in
                    let currentSteps = data.numberOfSteps.intValue
                    self.stepCount = currentSteps
                    
                    // 計算步頻（每分鐘步數）
                    let now = Date()
                    let timeInterval = now.timeIntervalSince(self.lastCadenceUpdate)
                    
                    if timeInterval >= 1.0 { // 每秒更新一次
                        let stepsInInterval = currentSteps - self.lastStepCount
                        self.cadence = Double(stepsInInterval) / timeInterval * 60.0
                        self.lastStepCount = currentSteps
                        self.lastCadenceUpdate = now
                    }
                }
            }
        }
    }
    
    func stop() {
        guard isRunning else { return }
        
        isRunning = false
        timer?.invalidate()
        timer = nil
        pedometer.stopUpdates()
    }
    
    func reset() {
        stop()
        elapsedTime = 0
        stepCount = 0
        cadence = 0
        startDate = nil
        lastStepCount = 0
    }
    
    deinit {
        stop()
    }
}
