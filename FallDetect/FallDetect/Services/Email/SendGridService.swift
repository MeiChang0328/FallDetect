//
//  SendGridService.swift
//  FallDetect
//
//  Created on 2025/12/22.
//  SendGrid 郵件發送服務
//

import Foundation
import Observation

/// SendGrid 郵件服務
@Observable
final class SendGridService {
    
    // MARK: - Singleton
    
    static let shared = SendGridService()
    
    // MARK: - Properties
    
    private let networkManager = NetworkManager.shared
    private let keychainHelper = KeychainHelper.shared
    private let sendGridAPIURL = "https://api.sendgrid.com/v3/mail/send"
    
    /// 最後一次發送郵件的時間
    var lastEmailSentDate: Date?
    
    /// 郵件發送冷卻時間（秒）
    private let cooldownPeriod: TimeInterval = 300 // 5 分鐘
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 發送跌倒警告郵件
    /// - Parameters:
    ///   - recipientEmail: 收件人 Email
    ///   - senderEmail: 寄件人 Email
    ///   - senderName: 寄件人姓名
    ///   - timestamp: 跌倒發生時間
    ///   - confidence: 信心度
    ///   - maxImpact: 最大衝擊力
    ///   - hadRotation: 是否有旋轉
    ///   - latitude: 緯度（可選）
    ///   - longitude: 經度（可選）
    /// - Returns: 是否成功發送
    func sendFallAlertEmail(
        to recipientEmail: String,
        from senderEmail: String,
        senderName: String,
        timestamp: Date,
        confidence: Double,
        maxImpact: Double,
        hadRotation: Bool,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async throws -> Bool {
        
        // 檢查冷卻時間
        if let lastSent = lastEmailSentDate {
            let timeSinceLastEmail = Date().timeIntervalSince(lastSent)
            if timeSinceLastEmail < cooldownPeriod {
                let remainingTime = Int(cooldownPeriod - timeSinceLastEmail)
                throw SendGridError.cooldownPeriod(remainingSeconds: remainingTime)
            }
        }
        
        // 取得 API Key
        guard let apiKey = keychainHelper.getSendGridAPIKey() else {
            throw SendGridError.missingAPIKey
        }
        
        // 生成 HTML 內容
        let htmlContent = EmailTemplate.fallAlertHTML(
            senderName: senderName,
            timestamp: timestamp,
            confidence: confidence,
            maxImpact: maxImpact,
            hadRotation: hadRotation,
            latitude: latitude,
            longitude: longitude
        )
        
        // 建立請求
        let request = SendGridRequest.createFallAlertEmail(
            to: recipientEmail,
            from: senderEmail,
            fromName: senderName,
            htmlContent: htmlContent
        )
        
        // 發送請求
        let success = try await sendEmail(request: request, apiKey: apiKey)
        
        if success {
            lastEmailSentDate = Date()
        }
        
        return success
    }
    
    /// 發送測試郵件
    /// - Parameters:
    ///   - recipientEmail: 收件人 Email
    ///   - senderEmail: 寄件人 Email
    ///   - senderName: 寄件人姓名
    ///   - latitude: 緯度（可選）
    ///   - longitude: 經度（可選）
    /// - Returns: 是否成功發送
    func sendTestEmail(
        to recipientEmail: String,
        from senderEmail: String,
        senderName: String,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async throws -> Bool {
        
        // 取得 API Key
        guard let apiKey = keychainHelper.getSendGridAPIKey() else {
            throw SendGridError.missingAPIKey
        }
        
        // 生成測試郵件 HTML（跌倒警示格式）
        let htmlContent = EmailTemplate.testEmailHTML(
            senderName: senderName,
            latitude: latitude,
            longitude: longitude
        )
        
        // 建立請求
        let request = SendGridRequest.createEmail(
            to: recipientEmail,
            from: senderEmail,
            fromName: senderName,
            subject: "🚨 FallDetect 跌倒警示測試",
            htmlContent: htmlContent
        )
        
        // 發送請求
        return try await sendEmail(request: request, apiKey: apiKey)
    }
    
    /// 檢查是否可以發送郵件（冷卻時間檢查）
    /// - Returns: (可以發送, 剩餘冷卻秒數)
    func canSendEmail() -> (canSend: Bool, remainingSeconds: Int) {
        guard let lastSent = lastEmailSentDate else {
            return (true, 0)
        }
        
        let timeSinceLastEmail = Date().timeIntervalSince(lastSent)
        if timeSinceLastEmail >= cooldownPeriod {
            return (true, 0)
        } else {
            let remaining = Int(cooldownPeriod - timeSinceLastEmail)
            return (false, remaining)
        }
    }
    
    // MARK: - Private Methods
    
    /// 發送郵件到 SendGrid API
    /// - Parameters:
    ///   - request: SendGridRequest
    ///   - apiKey: API Key
    /// - Returns: 是否成功
    private func sendEmail(request: SendGridRequest, apiKey: String) async throws -> Bool {
        guard let url = URL(string: sendGridAPIURL) else {
            throw SendGridError.invalidURL
        }
        
        // 調試：顯示 API Key 前幾個字元
        let maskedKey = String(apiKey.prefix(8)) + "..." + String(apiKey.suffix(4))
        print("🔑 SendGrid API Key: \(maskedKey)")
        
        // 調試：顯示請求 JSON
        if let jsonData = try? JSONEncoder().encode(request),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 SendGrid Request JSON:")
            print(jsonString)
        }
        
        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        
        do {
            let responseData = try await networkManager.post(
                to: url,
                body: request,
                headers: headers
            )
            
            // 調試：顯示回應
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("📥 SendGrid Response: \(responseString)")
            }
            
            print("✅ SendGrid: 郵件發送成功")
            return true
            
        } catch let error as NetworkError {
            print("❌ SendGrid: 網路錯誤 - \(error.localizedDescription)")
            throw SendGridError.networkError(error)
        } catch {
            print("❌ SendGrid: 未知錯誤 - \(error.localizedDescription)")
            throw SendGridError.unknownError(error)
        }
    }
}

// MARK: - SendGrid Error

enum SendGridError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case networkError(NetworkError)
    case cooldownPeriod(remainingSeconds: Int)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "未設定 SendGrid API Key，請至設定頁面配置"
        case .invalidURL:
            return "無效的 SendGrid API URL"
        case .networkError(let error):
            return "網路錯誤：\(error.localizedDescription)"
        case .cooldownPeriod(let seconds):
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if minutes > 0 {
                return "請等待 \(minutes) 分 \(remainingSeconds) 秒後再發送"
            } else {
                return "請等待 \(seconds) 秒後再發送"
            }
        case .unknownError(let error):
            return "未知錯誤：\(error.localizedDescription)"
        }
    }
}
