//
//  AppSettings.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/16.
//  Refactored from Settings.swift to use SwiftData
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    // MARK: - 跌倒偵測設定
    
    /// 是否啟用跌倒偵測
    var isFallDetectionEnabled: Bool
    
    /// 跌倒偵測模式（儲存為字串）
    var fallDetectionModeRawValue: String
    
    // MARK: - Email 設定
    
    /// 緊急聯絡人 Email
    var emergencyEmail: String
    
    /// 是否啟用 Email 通知
    var enableEmailNotifications: Bool
    
    /// 最後一次發送 Email 的時間
    var lastEmailSentDate: Date?
    
    // MARK: - SendGrid 設定
    
    /// 是否已設定 SendGrid API Key（實際 Key 存在 Keychain）
    var hasSendGridAPIKey: Bool
    
    /// 發件人 Email（需在 SendGrid 驗證）
    var senderEmail: String
    
    /// 發件人名稱
    var senderName: String
    
    // MARK: - App 設定
    
    /// Dark Mode 設定（nil = 跟隨系統）
    var isDarkModeEnabled: Bool?
    
    /// App 版本號（用於追蹤升級）
    var appVersion: String
    
    /// 上次開啟 App 的時間
    var lastOpenedDate: Date?
    
    // MARK: - Initialization
    
    init(
        isFallDetectionEnabled: Bool = true,
        fallDetectionMode: DetectionMode = .sensitive,
        emergencyEmail: String = "",
        enableEmailNotifications: Bool = true,
        lastEmailSentDate: Date? = nil,
        hasSendGridAPIKey: Bool = false,
        senderEmail: String = "",
        senderName: String = "FallDetect 跌倒偵測系統",
        isDarkModeEnabled: Bool? = nil,
        appVersion: String = "2.0",
        lastOpenedDate: Date? = nil
    ) {
        self.isFallDetectionEnabled = isFallDetectionEnabled
        self.fallDetectionModeRawValue = fallDetectionMode.rawValue
        self.emergencyEmail = emergencyEmail
        self.enableEmailNotifications = enableEmailNotifications
        self.lastEmailSentDate = lastEmailSentDate
        self.hasSendGridAPIKey = hasSendGridAPIKey
        self.senderEmail = senderEmail
        self.senderName = senderName
        self.isDarkModeEnabled = isDarkModeEnabled
        self.appVersion = appVersion
        self.lastOpenedDate = lastOpenedDate
    }
    
    // MARK: - Computed Properties
    
    /// 跌倒偵測模式（轉換為 enum）
    var fallDetectionMode: DetectionMode {
        get {
            DetectionMode(rawValue: fallDetectionModeRawValue) ?? .sensitive
        }
        set {
            fallDetectionModeRawValue = newValue.rawValue
        }
    }
    
    /// 是否可以發送 Email（檢查冷卻時間）
    var canSendEmail: Bool {
        guard let lastSent = lastEmailSentDate else { return true }
        let cooldownPeriod: TimeInterval = 5 * 60 // 5 分鐘
        return Date().timeIntervalSince(lastSent) > cooldownPeriod
    }
    
    /// Email 設定是否完整
    var isEmailConfigured: Bool {
        return !emergencyEmail.isEmpty && hasSendGridAPIKey && !senderEmail.isEmpty
    }
    
    /// 距離上次發送的時間描述
    var timeSinceLastEmail: String? {
        guard let lastSent = lastEmailSentDate else { return nil }
        let interval = Date().timeIntervalSince(lastSent)
        let minutes = Int(interval / 60)
        
        if minutes < 60 {
            return "\(minutes) 分鐘前"
        } else {
            let hours = minutes / 60
            return "\(hours) 小時前"
        }
    }
    
    // MARK: - Static Shared Instance
    
    /// 共用實例（在 App 初始化時設定）
    static var shared: AppSettings?
}
