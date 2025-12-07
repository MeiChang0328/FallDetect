//
//  RunTracker.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import Foundation
import CoreMotion
import Combine

class RunTracker: ObservableObject {
    @Published var isRunning = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var stepCount: Int = 0
    @Published var cadence: Double = 0 // 每分鐘步頻
    
    private var timer: Timer?
    private let pedometer = CMPedometer()
    private var startDate: Date?
    private var startStepCount: Int = 0
    private var lastStepCount: Int = 0
    private var lastCadenceUpdate: Date = Date()
    
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
                
                DispatchQueue.main.async {
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
}

