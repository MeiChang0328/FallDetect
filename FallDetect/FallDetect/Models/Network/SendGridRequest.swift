//
//  SendGridRequest.swift
//  FallDetect
//
//  Created on 2025/12/22.
//  SendGrid API 請求模型
//

import Foundation

// MARK: - SendGrid Request Models

/// SendGrid 郵件發送請求
struct SendGridRequest: Codable {
    let personalizations: [Personalization]
    let from: EmailAddress
    let replyTo: EmailAddress?
    let content: [Content]
    
    struct Personalization: Codable {
        let to: [EmailAddress]
        let subject: String
    }
    
    struct EmailAddress: Codable {
        let email: String
        let name: String?
    }
    
    struct Content: Codable {
        let type: String
        let value: String
    }
    
    enum CodingKeys: String, CodingKey {
        case personalizations
        case from
        case replyTo = "reply_to"
        case content
    }
}

// MARK: - SendGrid Response Models

/// SendGrid API 回應
struct SendGridResponse: Codable {
    let message: String?
    let errors: [SendGridError]?
    
    struct SendGridError: Codable {
        let message: String
        let field: String?
        let help: String?
    }
}

// MARK: - Convenience Initializers

extension SendGridRequest {
    
    /// 建立簡單的郵件請求
    /// - Parameters:
    ///   - to: 收件人 Email
    ///   - toName: 收件人姓名（可選）
    ///   - from: 寄件人 Email
    ///   - fromName: 寄件人姓名（可選）
    ///   - subject: 郵件主旨
    ///   - htmlContent: HTML 內容
    /// - Returns: SendGridRequest 實例
    static func createEmail(
        to: String,
        toName: String? = nil,
        from: String,
        fromName: String? = nil,
        subject: String,
        htmlContent: String
    ) -> SendGridRequest {
        return SendGridRequest(
            personalizations: [
                Personalization(
                    to: [EmailAddress(email: to, name: toName)],
                    subject: subject
                )
            ],
            from: EmailAddress(email: from, name: fromName),
            replyTo: EmailAddress(email: from, name: fromName), // 添加 reply_to 提升可信度
            content: [
                Content(type: "text/html", value: htmlContent)
            ]
        )
    }
    
    /// 建立跌倒警告郵件請求
    /// - Parameters:
    ///   - to: 收件人 Email
    ///   - from: 寄件人 Email
    ///   - fromName: 寄件人姓名
    ///   - htmlContent: HTML 內容
    /// - Returns: SendGridRequest 實例
    static func createFallAlertEmail(
        to: String,
        from: String,
        fromName: String,
        htmlContent: String
    ) -> SendGridRequest {
        return createEmail(
            to: to,
            toName: nil,
            from: from,
            fromName: fromName,
            subject: "🚨 跌倒偵測警告 - 緊急通知",
            htmlContent: htmlContent
        )
    }
}
