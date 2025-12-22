//
//  RunTrackingView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use SwiftData and @Observable on 2025/12/16
//

import SwiftUI
import SwiftData
import CoreMotion
import MessageUI
import AudioToolbox
import CoreHaptics
import Combine

struct RunTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]
    
    @State private var tracker = RunTracker()
    @State private var locationManager = LocationManager()
    @State private var motionManager = MotionManager()
    @State private var fallDetection = FallDetection()
    @State private var metronome = Metronome()
    
    private let sendGridService = SendGridService.shared
    
    @State private var showSummary = false
    @State private var showSensorData = false
    @State private var showFallAlert = false
    @State private var showMailComposer = false
    @State private var mailComposer: MFMailComposeViewController?
    @State private var shouldPresentMailOnAlertDismiss = false
    @State private var hapticEngine: CHHapticEngine?
    @State private var alertHapticTimer: Timer?
    @State private var fallEventsCollected: [FallDetection.FallEventData] = []
    @State private var isSendingEmail = false
    
    private var settings: AppSettings? {
        settingsArray.first
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 漸變背景
            LinearGradient(
                colors: [Color.appBackground, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 主要時間顯示 - 使用新字體
                    VStack(spacing: 8) {
                        Text("跑步時間")
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                        
                        Text(formatTime(tracker.elapsedTime))
                            .font(.appMonospacedLarge)
                            .foregroundColor(.appTextPrimary)
                    }
                    .padding(.top, 80)
                    .padding(.bottom, 20)
                    
                    // 統計卡片 - 使用 StatCard
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            icon: "figure.walk",
                            title: "步數",
                            value: "\(tracker.stepCount)",
                            unit: "步",
                            color: .appPrimary,
                            style: .minimal
                        )
                        
                        StatCard(
                            icon: "gauge",
                            title: "步頻",
                            value: "\(Int(tracker.cadence))",
                            unit: "步/分",
                            color: .appSuccess,
                            style: .minimal
                        )
                    }
                    .padding(.horizontal)
                    .padding(.horizontal)
                    
                    // 節拍器控制 - 可拖拉設計
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "metronome")
                                .font(.appBody)
                                .foregroundColor(.appSecondary)
                            Text("節拍器")
                                .font(.appBodySecondary)
                                .foregroundColor(.appTextSecondary)
                            Spacer()
                            VStack(spacing: 2) {
                                Text("\(metronome.bpm)")
                                    .font(.appNumberLarge)
                                    .foregroundColor(.appTextPrimary)
                                Text("BPM")
                                    .font(.appCaption2)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        
                        // 可拖拉的滑桿
                        VStack(spacing: 8) {
                            Slider(
                                value: Binding(
                                    get: { Double(metronome.bpm) },
                                    set: { newValue in
                                        let roundedValue = Int(newValue)
                                        if roundedValue != metronome.bpm {
                                            metronome.setBPM(roundedValue)
                                            // 觸覺反饋
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                        }
                                    }
                                ),
                                in: 120...200,
                                step: 1
                            )
                            .tint(
                                LinearGradient(
                                    colors: [.appPrimary, .appSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            
                            // 範圍標籤
                            HStack {
                                Text("120")
                                    .font(.appCaption2)
                                    .foregroundColor(.appTextSecondary)
                                Spacer()
                                Text("160")
                                    .font(.appCaption2)
                                    .foregroundColor(.appTextSecondary)
                                Spacer()
                                Text("200")
                                    .font(.appCaption2)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        
                        // 快速調整按鈕（-5 / -1 / +1 / +5）
                        HStack(spacing: 12) {
                            Button(action: {
                                metronome.setBPM(max(120, metronome.bpm - 5))
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }) {
                                Text("-5")
                                    .font(.appCaption)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 32)
                                    .background(Color.appSecondary.opacity(0.7))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                metronome.decreaseBPM()
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                Image(systemName: "minus")
                                    .font(.appCaption)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 32)
                                    .background(Color.appSecondary)
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                metronome.increaseBPM()
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                Image(systemName: "plus")
                                    .font(.appCaption)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 32)
                                    .background(Color.appSecondary)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                metronome.setBPM(min(200, metronome.bpm + 5))
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }) {
                                Text("+5")
                                    .font(.appCaption)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 32)
                                    .background(Color.appSecondary.opacity(0.7))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.appShadowLight, radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // 位置資訊
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.appCaption)
                            .foregroundColor(.appPrimary)
                        Text(locationManager.locationString)
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal)
                    
                    // 跌倒偵測狀態
                    if tracker.isRunning {
                        fallDetectionStatusView
                    }
                    
                    // 感測器數據（可展開）
                    if showSensorData {
                        sensorDataView
                    }
                    
                    // 開始/停止按鈕
                    startStopButton
                    
                    // 測試按鈕
                    if tracker.isRunning {
                        testFallButton
                    }
                }
                .padding(.top, 60) // 為右上角按鈕留空間
            }
            
            // 右上角寄信按鈕
            emailButton
        }
        .onAppear {
            setupView()
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            analyzeFallDetection()
        }
        .sheet(isPresented: $showSummary) {
            RunSummaryView(
                tracker: tracker,
                location: locationManager.location,
                fallEvents: fallEventsCollected
            )
        }
        .sheet(isPresented: $showMailComposer, onDismiss: {
            mailComposer = nil
            fallDetection.reset()
        }) {
            if let composer = mailComposer {
                MailComposerView(mailComposer: composer)
            }
        }
        .alert("跌倒偵測", isPresented: $showFallAlert) {
            Button("確定", role: .cancel) {
                handleFallAlertDismiss()
            }
        } message: {
            Text("系統偵測到可能的跌倒事件。請確認您的安全狀況。")
        }
    }
    
    // MARK: - Subviews
    
    private var fallDetectionStatusView: some View {
        HStack(spacing: 12) {
            Image(systemName: fallDetection.isFallDetected ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                .font(.system(size: 24))
                .foregroundColor(fallDetection.isFallDetected ? .appDanger : .appSuccess)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(fallDetection.isFallDetected ? "偵測到跌倒！" : "跌倒偵測中")
                    .font(.appBodySecondary)
                    .fontWeight(.semibold)
                    .foregroundColor(fallDetection.isFallDetected ? .appDanger : .appSuccess)
                
                HStack(spacing: 8) {
                    if fallDetection.fallConfidence > 0 {
                        Text("信心度: \(Int(fallDetection.fallConfidence * 100))%")
                            .font(.appCaption2)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    if let mode = settings?.fallDetectionMode {
                        Text("•")
                            .foregroundColor(.appTextTertiary)
                        Text(mode.displayName)
                            .font(.appCaption2)
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            (fallDetection.isFallDetected ? Color.appDanger : Color.appSuccess)
                .opacity(0.08)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    (fallDetection.isFallDetected ? Color.appDanger : Color.appSuccess).opacity(0.2),
                    lineWidth: 1
                )
        )
        .padding(.horizontal)
    }
    
    private var sensorDataView: some View {
        VStack(spacing: 10) {
            // 加速度計數據
            VStack(alignment: .leading, spacing: 5) {
                Text("加速度 (G)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    SensorDataItem(label: "X", value: motionManager.acceleration.x)
                    SensorDataItem(label: "Y", value: motionManager.acceleration.y)
                    SensorDataItem(label: "Z", value: motionManager.acceleration.z)
                    SensorDataItem(label: "總", value: motionManager.totalAcceleration)
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 陀螺儀數據
            VStack(alignment: .leading, spacing: 5) {
                Text("角速度 (rad/s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    SensorDataItem(label: "X", value: motionManager.rotationRate.x)
                    SensorDataItem(label: "Y", value: motionManager.rotationRate.y)
                    SensorDataItem(label: "Z", value: motionManager.rotationRate.z)
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
    
    private var startStopButton: some View {
        Button(action: {
            if tracker.isRunning {
                stopRun()
            } else {
                startRun()
            }
            
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }) {
            HStack(spacing: 12) {
                Image(systemName: tracker.isRunning ? "stop.fill" : "play.fill")
                    .font(.appButtonPrimary)
                Text(tracker.isRunning ? "停止跑步" : "開始跑步")
                    .font(.appButtonPrimary)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: tracker.isRunning ? 
                        [Color.appDanger, Color.appDanger.opacity(0.8)] : 
                        [Color.appSuccess, Color.appSuccess.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: (tracker.isRunning ? Color.appDanger : Color.appSuccess).opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var testFallButton: some View {
        Button(action: {
            testFallDetection()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.appButtonSecondary)
                Text("測試跌倒偵測")
                    .font(.appButtonSecondary)
            }
            .foregroundColor(.appWarning)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.appWarning.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appWarning.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    private var emailButton: some View {
        Button(action: {
            sendFallAlertEmail()
        }) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.appShadowMedium, radius: 6, x: 0, y: 3)
        }
        .padding(.top, 60)
        .padding(.trailing, 20)
    }
    
    // MARK: - Actions
    
    private func setupView() {
        locationManager.requestPermission()
        prepareHaptics()
        
        // 設定跌倒偵測回調
        fallDetection.onFallDetected = { eventData in
            fallEventsCollected.append(eventData)
            showFallAlert = true
            shouldPresentMailOnAlertDismiss = true
            startAlertHapticLoop()
            
            // 自動發送 Email 通知（如果有啟用）
            if let settings = settings,
               settings.isFallDetectionEnabled,
               settings.enableEmailNotifications,
               !settings.emergencyEmail.isEmpty,
               KeychainHelper.shared.hasSendGridAPIKey() {
                sendFallAlertEmail(eventData: eventData)
            }
        }
        
        // 同步偵測模式
        if let settingsMode = settings?.fallDetectionMode {
            fallDetection.updateMode(settingsMode)
        }
    }
    
    private func startRun() {
        tracker.start()
        locationManager.startLocationUpdates()
        motionManager.startUpdates()
        fallDetection.reset()
        fallEventsCollected.removeAll()
        metronome.start()
    }
    
    private func stopRun() {
        tracker.stop()
        locationManager.stopLocationUpdates()
        motionManager.stopUpdates()
        fallDetection.reset()
        metronome.stop()
        showSummary = true
    }
    
    private func analyzeFallDetection() {
        guard tracker.isRunning else { return }
        guard settings?.isFallDetectionEnabled ?? false else { return }
        
        let location = locationManager.location.map { loc in
            (latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        }
        
        fallDetection.analyzeMotion(
            acceleration: motionManager.acceleration,
            rotationRate: motionManager.rotationRate,
            attitude: motionManager.attitude,
            location: location
        )
    }
    
    private func testFallDetection() {
        let location = locationManager.location.map { loc in
            (latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        }
        fallDetection.triggerTestFall(location: location)
    }
    
    private func handleFallAlertDismiss() {
        stopAlertHapticLoop()
        fallDetection.reset()
        
        if shouldPresentMailOnAlertDismiss {
            shouldPresentMailOnAlertDismiss = false
            if let settings = settings,
               settings.isFallDetectionEnabled,
               settings.enableEmailNotifications,
               !settings.emergencyEmail.isEmpty {
                sendFallAlertEmail()
            }
        }
    }
    
    private func sendFallAlertEmail() {
        guard let settings = settings else { return }
        
        let locationString = locationManager.location != nil ? locationManager.locationString : nil
        if let composer = EmailService.shared.sendFallAlertEmail(
            to: settings.emergencyEmail,
            location: locationString
        ) {
            mailComposer = composer
            showMailComposer = true
        }
    }
    
    // MARK: - Haptics
    
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
                
                // 三次強烈敲擊
                for i in 0..<3 {
                    let time = Double(i) * 0.15
                    let tap = CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                        ],
                        relativeTime: time
                    )
                    events.append(tap)
                }
                
                // 持續強烈震動
                let continuousBuzz = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: 0.5,
                    duration: 0.8
                )
                events.append(continuousBuzz)
                
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                fallbackStrongVibration()
            }
        } else {
            fallbackStrongVibration()
        }
    }
    
    private func fallbackStrongVibration() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
            heavyGenerator.impactOccurred(intensity: 1.0)
        }
    }
    
    private func startAlertHapticLoop() {
        triggerStrongAlertHaptics()
        alertHapticTimer?.invalidate()
        alertHapticTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            triggerStrongAlertHaptics()
        }
    }
    
    private func stopAlertHapticLoop() {
        alertHapticTimer?.invalidate()
        alertHapticTimer = nil
    }
    
    // MARK: - Email Sending
    
    private func sendFallAlertEmail(eventData: FallDetection.FallEventData) {
        guard let settings = settings else { return }
        guard !isSendingEmail else { return } // 防止重複發送
        
        // 檢查冷卻時間
        let (canSend, remaining) = sendGridService.canSendEmail()
        guard canSend else {
            print("⏳ Email 冷卻中，剩餘 \(remaining) 秒")
            return
        }
        
        isSendingEmail = true
        
        Task {
            do {
                let senderEmail = "lovec8c81@gmail.com" // 使用已驗證的 Gmail 地址
                let success = try await sendGridService.sendFallAlertEmail(
                    to: settings.emergencyEmail,
                    from: senderEmail,
                    senderName: settings.senderName,
                    timestamp: eventData.timestamp,
                    confidence: eventData.confidence,
                    maxImpact: eventData.maxImpact,
                    hadRotation: eventData.hadRotation,
                    latitude: eventData.latitude,
                    longitude: eventData.longitude
                )
                
                await MainActor.run {
                    isSendingEmail = false
                    if success {
                        print("✅ 跌倒警告郵件已發送到 \(settings.emergencyEmail)")
                    }
                }
            } catch {
                await MainActor.run {
                    isSendingEmail = false
                    print("❌ 發送跌倒警告郵件失敗: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
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

// MARK: - Mail Composer View

struct MailComposerView: UIViewControllerRepresentable {
    let mailComposer: MFMailComposeViewController
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Sensor Data Item

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

// MARK: - Previews

#Preview {
    RunTrackingView()
        .modelContainer(ModelContainer.preview)
}
