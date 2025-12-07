//
//  RunTrackingView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import SwiftUI
import CoreMotion
import Combine
import MessageUI
import AudioToolbox
import CoreHaptics

struct RunTrackingView: View {
    @StateObject private var tracker = RunTracker()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var motionManager = MotionManager()
    @StateObject private var fallDetection = FallDetection()
    @ObservedObject var recordStore: RunRecordStore
    @ObservedObject var settings = Settings.shared
    @State private var showSummary = false
    @State private var showSensorData = false
    @State private var showFallAlert = false
    @State private var showMailComposer = false
    @State private var mailComposer: MFMailComposeViewController?
    @State private var shouldPresentMailOnAlertDismiss = false
    @State private var hapticEngine: CHHapticEngine?
    @State private var alertHapticTimer: Timer?

    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            
            // 跌倒偵測狀態（僅在跑步時顯示）
            if tracker.isRunning {
                VStack(spacing: 5) {
                    HStack {
                        Image(systemName: fallDetection.isFallDetected ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundColor(fallDetection.isFallDetected ? .red : .green)
                        Text(fallDetection.isFallDetected ? "偵測到跌倒！" : "跌倒偵測中")
                            .font(.caption)
                            .foregroundColor(fallDetection.isFallDetected ? .red : .secondary)
                    }
                    if fallDetection.fallConfidence > 0 {
                        Text("信心度: \(Int(fallDetection.fallConfidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(fallDetection.isFallDetected ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
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
                    fallDetection.reset()
                    showSummary = true
                } else {
                    tracker.start()
                    locationManager.startLocationUpdates()
                    motionManager.startUpdates()
                    fallDetection.reset()
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
            .padding(.bottom, 10)
            
            // 測試按鈕（保留）
            Button(action: {
                fallDetection.triggerTestFall()
            }) {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("測試跌倒事件")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
            }

            }
            // 右上角圓形按鈕
            Button(action: {
                sendFallAlertEmail()
            }) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.blue))
                    .shadow(radius: 2)
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        .onAppear {
            locationManager.requestPermission()
            prepareHaptics()
            fallDetection.onFallDetected = {
                // 顯示 Alert，並在關閉後再彈出寄信視窗
                showFallAlert = true
                shouldPresentMailOnAlertDismiss = true
                // 開始震動循環
                startAlertHapticLoop()
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            // 定期分析感測器數據進行跌倒偵測
            if tracker.isRunning, let attitude = motionManager.attitude {
                fallDetection.analyzeMotion(
                    acceleration: motionManager.acceleration,
                    rotationRate: motionManager.rotationRate,
                    attitude: attitude
                )
            }
        }
        .sheet(isPresented: $showSummary) {
            RunSummaryView(tracker: tracker, location: locationManager.location, recordStore: recordStore)
        }
        .sheet(isPresented: $showMailComposer, onDismiss: {
            // 關閉寄信視窗後重置跌倒偵測狀態，持續跑步不停止
            mailComposer = nil
            fallDetection.reset()
        }) {
            if let composer = mailComposer {
                MailComposerView(mailComposer: composer)
            }
        }
        // 跌倒偵測提醒 Alert
        .alert("跌倒偵測", isPresented: $showFallAlert) {
            Button("確定", role: .cancel) {
                // 停止震動循環
                stopAlertHapticLoop()
                // 重置偵測狀態，但不停止跑步
                fallDetection.reset()
                if shouldPresentMailOnAlertDismiss {
                    shouldPresentMailOnAlertDismiss = false
                    if settings.isFallDetectionEnabled && !settings.emergencyEmail.isEmpty {
                        sendFallAlertEmail()
                    }
                }
            }
        } message: {
            Text("系統偵測到可能的跌倒事件。請確認您的安全狀況。")
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
    
    private func sendFallAlertEmail() {
        let locationString = locationManager.location != nil ? locationManager.locationString : nil
        if let composer = EmailService.shared.sendFallAlertEmail(to: settings.emergencyEmail, location: locationString) {
            mailComposer = composer
            showMailComposer = true
        }
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptics engine start error: \(error)")
            hapticEngine = nil
        }
    }
    
    private func triggerStrongAlertHaptics() {
        if let engine = hapticEngine {
            do {
                var events: [CHHapticEvent] = []
                // A sharp transient (like a tap)
                let sharpTap = CHHapticEvent(eventType: .hapticTransient,
                                             parameters: [
                                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                                             ],
                                             relativeTime: 0)
                events.append(sharpTap)
                // A short strong continuous buzz
                let buzz = CHHapticEvent(eventType: .hapticContinuous,
                                         parameters: [
                                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                                         ],
                                         relativeTime: 0.05,
                                         duration: 0.4)
                events.append(buzz)
                
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
                
                // Repeat the pattern a few times with small gaps for attention
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { try? player.start(atTime: 0) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { try? player.start(atTime: 0) }
            } catch {
                // Fallback to repeated system vibration
                fallbackStrongVibration()
            }
        } else {
            fallbackStrongVibration()
        }
    }
    
    private func fallbackStrongVibration() {
        // Repeat system vibration 3 times with short intervals as a fallback
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // 啟動警示震動循環
    private func startAlertHapticLoop() {
        // 先觸發一次強烈觸覺
        triggerStrongAlertHaptics()
        // 每 1.2 秒重複一次，直到 Alert 關閉
        alertHapticTimer?.invalidate()
        alertHapticTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            triggerStrongAlertHaptics()
        }
    }
    
    private func stopAlertHapticLoop() {
        alertHapticTimer?.invalidate()
        alertHapticTimer = nil
    }
}

struct MailComposerView: UIViewControllerRepresentable {
    let mailComposer: MFMailComposeViewController
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // 不需要更新
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
