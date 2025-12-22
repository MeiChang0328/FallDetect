//
//  SettingsView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use SwiftData on 2025/12/16
//

import SwiftUI
import SwiftData
import CoreLocation

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]
    
    @State private var emailInput: String = ""
    @State private var apiKeyInput: String = ""
    @State private var showingAPIKeyAlert = false
    @State private var isSendingTestEmail = false
    @State private var testEmailResult: String?
    @State private var showTestEmailAlert = false
    @State private var locationManager = LocationManager()
    
    private let sendGridService = SendGridService.shared
    
    // 使用 @Bindable 需要 computed property
    private var settings: AppSettings? {
        settingsArray.first
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 漸變背景
                LinearGradient(
                    colors: [Color.appBackground, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 跌倒偵測設定
                        fallDetectionSection
                        
                        // 偵測模式選擇
                        detectionModeSection
                        
                        // Email 通知設定
                        emailNotificationSection
                        
                        // SendGrid API 設定
                        sendGridSection
                        
                        // 關於
                        aboutSection
                    }
                    .padding()
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadSettings()
            }
            .alert("測試郵件結果", isPresented: $showTestEmailAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(testEmailResult ?? "")
            }
        }
    }
    
    // MARK: - Sections
    
    private var fallDetectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "sensor.fill")
                    .font(.appBody)
                    .foregroundColor(.appPrimary)
                Text("跌倒偵測")
                    .font(.appTitle3)
                    .foregroundColor(.appTextPrimary)
            }
            
            // 開關與說明
            if let settings = settings {
                VStack(spacing: 12) {
                    HStack {
                        Text("啟用跌倒偵測")
                            .font(.appBody)
                            .foregroundColor(.appTextPrimary)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settings.isFallDetectionEnabled },
                            set: { newValue in
                                settings.isFallDetectionEnabled = newValue
                                saveSettings()
                            }
                        ))
                        .tint(.appPrimary)
                    }
                    
                    Text("當偵測到跌倒時，系統會自動發送 Email 通知給緊急聯絡人。")
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.appShadowLight, radius: 4, x: 0, y: 2)
    }
    
    private var detectionModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "speedometer")
                    .font(.appBody)
                    .foregroundColor(.appSecondary)
                Text("偵測靈敏度")
                    .font(.appTitle3)
                    .foregroundColor(.appTextPrimary)
            }
            
            if let settings = settings {
                VStack(spacing: 16) {
                    // 模式選擇器
                    Picker("靈敏度模式", selection: Binding(
                        get: { settings.fallDetectionMode },
                        set: { newValue in
                            settings.fallDetectionMode = newValue
                            saveSettings()
                        }
                    )) {
                        ForEach([DetectionMode.conservative, .balanced, .sensitive], id: \.self) { mode in
                            HStack {
                                Image(systemName: mode.iconName)
                                Text(mode.displayName)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.appPrimary)
                    
                    // 模式說明卡片
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: settings.fallDetectionMode.iconName)
                                .font(.appBody)
                                .foregroundColor(.appPrimary)
                            Text(settings.fallDetectionMode.displayName)
                                .font(.appBodySecondary)
                                .foregroundColor(.appTextPrimary)
                        }
                        
                        Text(settings.fallDetectionMode.description)
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.appSecondary)
                            Text("建議對象：\(settings.fallDetectionMode.recommendedFor)")
                                .font(.system(size: 11))
                                .foregroundColor(.appSecondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(12)
                    .background(Color.appPrimary.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.appShadowLight, radius: 4, x: 0, y: 2)
    }
    
    private var emailNotificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "envelope.fill")
                    .font(.appBody)
                    .foregroundColor(.appSuccess)
                Text("Email 通知設定")
                    .font(.appTitle3)
                    .foregroundColor(.appTextPrimary)
            }
            
            if let settings = settings {
                VStack(spacing: 16) {
                    // 開關
                    HStack {
                        Text("啟用 Email 通知")
                            .font(.appBody)
                            .foregroundColor(.appTextPrimary)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settings.enableEmailNotifications },
                            set: { newValue in
                                settings.enableEmailNotifications = newValue
                                saveSettings()
                            }
                        ))
                        .tint(.appSuccess)
                    }
                    
                    // 輸入欄位
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("緊急聯絡人 Email")
                                .font(.appCaption)
                                .foregroundColor(.appTextSecondary)
                            
                            TextField("請輸入 Email", text: $emailInput)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: emailInput) { _, newValue in
                                    settings.emergencyEmail = newValue
                                    saveSettings()
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("發送者名稱")
                                .font(.appCaption)
                                .foregroundColor(.appTextSecondary)
                            
                            TextField("請輸入名稱", text: Binding(
                                get: { settings.senderName },
                                set: { newValue in
                                    settings.senderName = newValue
                                    saveSettings()
                                }
                            ))
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    // 說明
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.appPrimary)
                        
                        Text("請輸入緊急聯絡人的 Email 地址。當偵測到跌倒時，系統會發送通知到此地址。")
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(10)
                    .background(Color.appPrimary.opacity(0.05))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.appShadowLight, radius: 4, x: 0, y: 2)
    }
    
    private var sendGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "key.fill")
                    .font(.appBody)
                    .foregroundColor(.appWarning)
                Text("SendGrid API 設定")
                    .font(.appTitle3)
                    .foregroundColor(.appTextPrimary)
            }
            
            if let settings = settings {
                VStack(spacing: 16) {
                    // API Key 狀態
                    HStack {
                        Text("API Key 狀態")
                            .font(.appBody)
                            .foregroundColor(.appTextPrimary)
                        
                        Spacer()
                        
                        if settings.hasSendGridAPIKey {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.appSuccess)
                                Text("已設定")
                                    .font(.appBodySecondary)
                                    .foregroundColor(.appSuccess)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.appDanger)
                                Text("未設定")
                                    .font(.appBodySecondary)
                                    .foregroundColor(.appDanger)
                            }
                        }
                    }
                    .padding(12)
                    .background(settings.hasSendGridAPIKey ? Color.appSuccess.opacity(0.05) : Color.appDanger.opacity(0.05))
                    .cornerRadius(10)
                    
                    // 按鈕
                    VStack(spacing: 10) {
                        Button(action: {
                            showingAPIKeyAlert = true
                        }) {
                            HStack {
                                Image(systemName: settings.hasSendGridAPIKey ? "arrow.triangle.2.circlepath" : "plus.circle.fill")
                                    .font(.appBody)
                                Text(settings.hasSendGridAPIKey ? "更新 API Key" : "設定 API Key")
                                    .font(.appBodySecondary)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(
                                LinearGradient(
                                    colors: [.appPrimary, .appSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.appPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        if settings.hasSendGridAPIKey {
                            Button(action: {
                                removeAPIKey()
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .font(.appBody)
                                    Text("移除 API Key")
                                        .font(.appBodySecondary)
                                }
                                .foregroundColor(.appDanger)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.appDanger.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // 測試郵件按鈕
                            Button(action: {
                                sendTestEmail()
                            }) {
                                HStack {
                                    if isSendingTestEmail {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                            .font(.appBody)
                                        Text("發送測試郵件")
                                            .font(.appBodySecondary)
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(
                                    LinearGradient(
                                        colors: [.appSuccess, .appPrimary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.appSuccess.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .disabled(isSendingTestEmail || (emailInput.isEmpty && (settings?.emergencyEmail.isEmpty ?? true)))
                            .opacity((isSendingTestEmail || (emailInput.isEmpty && (settings?.emergencyEmail.isEmpty ?? true))) ? 0.6 : 1.0)
                        }
                    }
                    
                    // 說明
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.appWarning)
                        
                        Text("需要 SendGrid API Key 才能發送 Email 通知。請前往 SendGrid 官網取得 API Key。")
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(10)
                    .background(Color.appWarning.opacity(0.05))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.appShadowLight, radius: 4, x: 0, y: 2)
        .alert("SendGrid API Key", isPresented: $showingAPIKeyAlert) {
            TextField("請輸入 API Key", text: $apiKeyInput)
            Button("取消", role: .cancel) {
                apiKeyInput = ""
            }
            Button("儲存") {
                saveAPIKey()
            }
        } message: {
            Text("請輸入您的 SendGrid API Key。此資訊將安全地儲存在裝置的 Keychain 中。")
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.appBody)
                    .foregroundColor(.appPrimary)
                Text("關於")
                    .font(.appTitle3)
                    .foregroundColor(.appTextPrimary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "app.badge")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                        Text("版本")
                            .font(.appBody)
                            .foregroundColor(.appTextPrimary)
                    }
                    Spacer()
                    Text("2.0")
                        .font(.appNumberSmall)
                        .foregroundColor(.appTextSecondary)
                }
                
                Divider()
                
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "gear")
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                        Text("模式")
                            .font(.appBody)
                            .foregroundColor(.appTextPrimary)
                    }
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String ?? "Unknown")
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.appShadowLight, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Actions
    
    private func loadSettings() {
        if let settings = settings {
            emailInput = settings.emergencyEmail
        }
    }
    
    private func saveSettings() {
        do {
            try modelContext.save()
        } catch {
            print("❌ 保存設定失敗: \(error.localizedDescription)")
        }
    }
    
    private func saveAPIKey() {
        guard !apiKeyInput.isEmpty else { return }
        
        // 使用 KeychainHelper 儲存 API Key
        do {
            try KeychainHelper.shared.saveSendGridAPIKey(apiKeyInput)
            
            if let settings = settings {
                settings.hasSendGridAPIKey = true
                saveSettings()
            }
            
            print("✅ API Key 已安全儲存到 Keychain")
        } catch {
            print("❌ 儲存 API Key 失敗: \(error.localizedDescription)")
        }
        
        apiKeyInput = ""
    }
    
    private func removeAPIKey() {
        // 使用 KeychainHelper 刪除 API Key
        do {
            try KeychainHelper.shared.deleteSendGridAPIKey()
            
            if let settings = settings {
                settings.hasSendGridAPIKey = false
                saveSettings()
            }
            
            print("✅ API Key 已從 Keychain 移除")
        } catch {
            print("❌ 移除 API Key 失敗: \(error.localizedDescription)")
        }
    }
    
    private func sendTestEmail() {
        guard let settings = settings else { return }
        
        // 確保使用最新的緊急聯絡人 Email
        let recipientEmail = settings.emergencyEmail.isEmpty ? emailInput : settings.emergencyEmail
        guard !recipientEmail.isEmpty else {
            testEmailResult = "❌ 請先設定緊急聯絡人 Email"
            showTestEmailAlert = true
            return
        }
        
        isSendingTestEmail = true
        
        Task {
            do {
                // 使用已驗證的 Gmail 地址作為寄件人
                let senderEmail = "lovec8c81@gmail.com"
                
                // 獲取當前位置（如果可用）
                let latitude = locationManager.location?.coordinate.latitude
                let longitude = locationManager.location?.coordinate.longitude
                
                let success = try await sendGridService.sendTestEmail(
                    to: recipientEmail,
                    from: senderEmail,
                    senderName: settings.senderName,
                    latitude: latitude,
                    longitude: longitude
                )
                
                await MainActor.run {
                    isSendingTestEmail = false
                    if success {
                        testEmailResult = "✅ 測試郵件已成功發送到 \(recipientEmail)\n請檢查您的收件匣（包括垃圾郵件資料夾）"
                    } else {
                        testEmailResult = "❌ 郵件發送失敗，請檢查設定"
                    }
                    showTestEmailAlert = true
                }
            } catch {
                await MainActor.run {
                    isSendingTestEmail = false
                    testEmailResult = "❌ 發送失敗：\(error.localizedDescription)"
                    showTestEmailAlert = true
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    SettingsView()
        .modelContainer(ModelContainer.preview)
}
