//
//  EmailService.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import Foundation
import MessageUI
import SwiftUI


class EmailService: NSObject, ObservableObject {
    static let shared = EmailService()
    
    @Published var canSendMail = false
    
    override init() {
        super.init()
        canSendMail = MFMailComposeViewController.canSendMail()
    }
    
    func sendFallAlertEmail(to email: String, location: String?) -> MFMailComposeViewController? {
        guard canSendMail else {
            print("無法發送 email：設備未設定郵件帳號")
            return nil
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([email])
        mailComposer.setSubject("跌倒偵測警告 - FallDetect")
        
        var messageBody = """
        這是一封自動發送的跌倒偵測警告。
        
        系統偵測到可能的跌倒事件。
        
        時間：\(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))
        """
        
        if let location = location, !location.isEmpty {
            messageBody += "\n\n位置：\(location)"
        }
        
        messageBody += """
        
        
        請確認當事人的安全狀況。
        
        此訊息由 FallDetect 應用程式自動發送。
        """
        
        mailComposer.setMessageBody(messageBody, isHTML: false)
        
        return mailComposer
    }
}

extension EmailService: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        
        switch result {
        case .sent:
            print("Email 已發送")
        case .cancelled:
            print("Email 已取消")
        case .failed:
            print("Email 發送失敗：\(error?.localizedDescription ?? "未知錯誤")")
        case .saved:
            print("Email 已儲存為草稿")
        @unknown default:
            break
        }
    }
}

