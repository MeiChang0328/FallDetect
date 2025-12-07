//
//  RunTrackingView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import SwiftUI
import CoreMotion

struct RunTrackingView: View {
    @StateObject private var tracker = RunTracker()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var motionManager = MotionManager()
    @ObservedObject var recordStore: RunRecordStore
    @State private var showSummary = false
    @State private var showSensorData = false
    
    var body: some View {
        VStack(spacing: 30) {
            // 時間顯示
            VStack(spacing: 10) {
                Text("跑步時間")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(formatTime(tracker.elapsedTime))
                    .font(.system(size: 48, weight: .bold))
            }
            .padding()
            
            // 步數顯示
            VStack(spacing: 10) {
                Text("步數")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("\(tracker.stepCount)")
                    .font(.system(size: 36, weight: .semibold))
            }
            .padding()
            
            // 步頻顯示
            VStack(spacing: 10) {
                Text("每分鐘步頻")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("\(Int(tracker.cadence)) 步/分鐘")
                    .font(.system(size: 24, weight: .medium))
            }
            .padding()
            
            // 位置顯示
            VStack(spacing: 10) {
                Text("位置")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(locationManager.locationString)
                    .font(.system(size: 14, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // 感測器數據（可展開）
            if showSensorData {
                VStack(spacing: 15) {
                    // 加速度計數據
                    VStack(alignment: .leading, spacing: 8) {
                        Text("加速度 (m/s²)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        HStack {
                            SensorDataItem(label: "X", value: motionManager.acceleration.x)
                            SensorDataItem(label: "Y", value: motionManager.acceleration.y)
                            SensorDataItem(label: "Z", value: motionManager.acceleration.z)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // 陀螺儀數據
                    VStack(alignment: .leading, spacing: 8) {
                        Text("角速度 (rad/s)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        HStack {
                            SensorDataItem(label: "X", value: motionManager.rotationRate.x)
                            SensorDataItem(label: "Y", value: motionManager.rotationRate.y)
                            SensorDataItem(label: "Z", value: motionManager.rotationRate.z)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            // 顯示/隱藏感測器數據按鈕
            Button(action: {
                showSensorData.toggle()
            }) {
                HStack {
                    Image(systemName: showSensorData ? "chevron.up" : "chevron.down")
                    Text(showSensorData ? "隱藏感測器數據" : "顯示感測器數據")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.top, 5)
            
            Spacer()
            
            // 開始/停止按鈕
            Button(action: {
                if tracker.isRunning {
                    tracker.stop()
                    locationManager.stopLocationUpdates()
                    motionManager.stopUpdates()
                    showSummary = true
                } else {
                    tracker.start()
                    locationManager.startLocationUpdates()
                    motionManager.startUpdates()
                }
            }) {
                Text(tracker.isRunning ? "停止" : "開始")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(tracker.isRunning ? Color.red : Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .sheet(isPresented: $showSummary) {
            RunSummaryView(tracker: tracker, location: locationManager.location, recordStore: recordStore)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct SensorDataItem: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.2f", value))
                .font(.system(size: 14, weight: .medium))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RunTrackingView(recordStore: RunRecordStore())
}

