//
//  EmailTemplate.swift
//  FallDetect
//
//  Created on 2025/12/22.
//  郵件範本生成器
//

import Foundation

/// 郵件範本生成器
struct EmailTemplate {
    
    // MARK: - Fall Alert Email
    
    /// 生成跌倒警告郵件的 HTML 內容
    /// - Parameters:
    ///   - senderName: 發送者姓名
    ///   - timestamp: 跌倒發生時間
    ///   - confidence: 信心度（0.0 ~ 1.0）
    ///   - maxImpact: 最大衝擊力（G）
    ///   - hadRotation: 是否有旋轉
    ///   - latitude: 緯度（可選）
    ///   - longitude: 經度（可選）
    /// - Returns: HTML 字串
    static func fallAlertHTML(
        senderName: String,
        timestamp: Date,
        confidence: Double,
        maxImpact: Double,
        hadRotation: Bool,
        latitude: Double?,
        longitude: Double?
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale(identifier: "zh_TW")
        let formattedDate = dateFormatter.string(from: timestamp)
        
        let confidencePercentage = Int(confidence * 100)
        let impactFormatted = String(format: "%.1f", maxImpact)
        
        var locationSection = ""
        if let lat = latitude, let lon = longitude {
            let googleMapsURL = "https://www.google.com/maps?q=\(lat),\(lon)"
            locationSection = """
            <tr>
                <td style="padding: 20px 0; border-top: 1px solid #eeeeee;">
                    <h3 style="color: #333333; margin: 0 0 10px 0;">📍 位置資訊</h3>
                    <p style="color: #666666; margin: 0 0 10px 0;">
                        座標：\(String(format: "%.6f", lat)), \(String(format: "%.6f", lon))
                    </p>
                    <a href="\(googleMapsURL)" 
                       style="display: inline-block; padding: 12px 24px; background: linear-gradient(135deg, #4A90E2 0%, #9B59B6 100%); color: white; text-decoration: none; border-radius: 6px; font-weight: 600;">
                        在 Google Maps 中查看
                    </a>
                </td>
            </tr>
            """
        }
        
        let rotationText = hadRotation ? "✅ 是（偵測到身體旋轉）" : "❌ 否"
        
        return """
        <!DOCTYPE html>
        <html lang="zh-TW">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>跌倒偵測警告</title>
        </head>
        <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
            <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #f5f5f5;">
                <tr>
                    <td style="padding: 40px 20px;">
                        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
                            <!-- 警告橫幅 -->
                            <tr>
                                <td style="background: linear-gradient(135deg, #E74C3C 0%, #F39C12 100%); padding: 30px; border-radius: 12px 12px 0 0; text-align: center;">
                                    <h1 style="color: white; margin: 0; font-size: 28px; font-weight: 700;">
                                        🚨 跌倒偵測警告
                                    </h1>
                                    <p style="color: white; margin: 10px 0 0 0; font-size: 16px; opacity: 0.95;">
                                        緊急通知 - 請立即查看
                                    </p>
                                </td>
                            </tr>
                            
                            <!-- 主要內容 -->
                            <tr>
                                <td style="padding: 30px;">
                                    <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
                                        您好，
                                    </p>
                                    <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
                                        <strong>\(senderName)</strong> 的 FallDetect 應用程式偵測到可能的跌倒事件。以下是詳細資訊：
                                    </p>
                                    
                                    <!-- 偵測詳情 -->
                                    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0;">
                                        <tr>
                                            <td>
                                                <h3 style="color: #333333; margin: 0 0 15px 0;">⏰ 發生時間</h3>
                                                <p style="color: #666666; margin: 0 0 20px 0; font-size: 15px;">
                                                    \(formattedDate)
                                                </p>
                                                
                                                <h3 style="color: #333333; margin: 0 0 15px 0;">📊 偵測數據</h3>
                                                <ul style="color: #666666; margin: 0; padding-left: 20px; list-style: none;">
                                                    <li style="margin-bottom: 10px;">
                                                        <strong>信心度：</strong> \(confidencePercentage)%
                                                    </li>
                                                    <li style="margin-bottom: 10px;">
                                                        <strong>最大衝擊力：</strong> \(impactFormatted) G
                                                    </li>
                                                    <li style="margin-bottom: 10px;">
                                                        <strong>身體旋轉：</strong> \(rotationText)
                                                    </li>
                                                </ul>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                            
                            <!-- 位置資訊（如果有） -->
                            \(locationSection)
                            
                            <!-- 建議行動 -->
                            <tr>
                                <td style="padding: 20px 30px; border-top: 1px solid #eeeeee;">
                                    <h3 style="color: #333333; margin: 0 0 10px 0;">💡 建議行動</h3>
                                    <ul style="color: #666666; margin: 0; padding-left: 20px; line-height: 1.8;">
                                        <li>立即嘗試聯絡 \(senderName)</li>
                                        <li>如果無法聯繫，請前往上述位置查看</li>
                                        <li>必要時請撥打緊急救援電話 119</li>
                                    </ul>
                                </td>
                            </tr>
                            
                            <!-- 頁尾 -->
                            <tr>
                                <td style="padding: 20px 30px; background-color: #f8f9fa; border-radius: 0 0 12px 12px; text-align: center;">
                                    <p style="color: #999999; margin: 0; font-size: 13px;">
                                        此郵件由 FallDetect 跌倒偵測系統自動發送<br>
                                        如有疑問，請聯絡 \(senderName)
                                    </p>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </body>
        </html>
        """
    }
    
    // MARK: - Test Email
    
    /// 生成測試郵件的 HTML 內容（跌倒警示格式）
    /// - Parameters:
    ///   - senderName: 發送者姓名
    ///   - latitude: 緯度（可選）
    ///   - longitude: 經度（可選）
    /// - Returns: HTML 字串
    static func testEmailHTML(
        senderName: String,
        latitude: Double?,
        longitude: Double?
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale(identifier: "zh_TW")
        let formattedDate = dateFormatter.string(from: Date())
        
        var locationSection = ""
        if let lat = latitude, let lon = longitude {
            let googleMapsURL = "https://www.google.com/maps?q=\(lat),\(lon)"
            locationSection = """
                                    <div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 20px; margin: 20px 0; border-radius: 8px;">
                                        <h3 style="color: #856404; margin: 0 0 15px 0; font-size: 18px;">📍 位置資訊</h3>
                                        <p style="color: #856404; margin: 0 0 10px 0; font-size: 15px;">
                                            <strong>緯度：</strong> \(String(format: "%.6f", lat))
                                        </p>
                                        <p style="color: #856404; margin: 0 0 15px 0; font-size: 15px;">
                                            <strong>經度：</strong> \(String(format: "%.6f", lon))
                                        </p>
                                        <a href="\(googleMapsURL)" style="display: inline-block; background-color: #ffc107; color: #000; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 15px;">
                                            🗺️ 在 Google 地圖中查看
                                        </a>
                                    </div>
            """
        } else {
            locationSection = """
                                    <div style="background-color: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0;">
                                        <p style="color: #666666; margin: 0; font-size: 15px;">
                                            📍 位置資訊未提供（請開啟定位權限）
                                        </p>
                                    </div>
            """
        }
        
        return """
        <!DOCTYPE html>
        <html lang="zh-TW">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>跌倒警示測試</title>
        </head>
        <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
            <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #f5f5f5;">
                <tr>
                    <td style="padding: 40px 20px;">
                        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
                            <!-- 警示標題 -->
                            <tr>
                                <td style="background: linear-gradient(135deg, #dc3545 0%, #c82333 100%); padding: 30px; border-radius: 12px 12px 0 0; text-align: center;">
                                    <h1 style="color: white; margin: 0; font-size: 32px; font-weight: 700;">
                                        🚨 跌倒警示測試
                                    </h1>
                                    <p style="color: white; margin: 10px 0 0 0; font-size: 16px; opacity: 0.95;">
                                        FallDetect 緊急通知系統
                                    </p>
                                </td>
                            </tr>
                            
                            <!-- 內容 -->
                            <tr>
                                <td style="padding: 40px 30px;">
                                    <div style="background-color: #d1ecf1; border-left: 4px solid #17a2b8; padding: 20px; margin: 0 0 20px 0; border-radius: 8px;">
                                        <p style="color: #0c5460; margin: 0; font-size: 16px; font-weight: 600;">
                                            ℹ️ 這是一封測試郵件
                                        </p>
                                        <p style="color: #0c5460; margin: 10px 0 0 0; font-size: 14px;">
                                            此郵件模擬真實跌倒警示的格式和內容
                                        </p>
                                    </div>
                                    
                                    <h2 style="color: #333333; margin: 0 0 20px 0; font-size: 20px;">警示詳情</h2>
                                    
                                    <div style="background-color: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0;">
                                        <p style="color: #333333; margin: 0 0 10px 0; font-size: 15px;">
                                            <strong>👤 使用者：</strong> \(senderName)
                                        </p>
                                        <p style="color: #333333; margin: 0 0 10px 0; font-size: 15px;">
                                            <strong>⏰ 測試時間：</strong> \(formattedDate)
                                        </p>
                                        <p style="color: #333333; margin: 0; font-size: 15px;">
                                            <strong>📱 系統：</strong> FallDetect v1.0
                                        </p>
                                    </div>
                                    
                                    \(locationSection)
                                    
                                    <div style="background-color: #d4edda; border-left: 4px solid #28a745; padding: 20px; margin: 20px 0; border-radius: 8px;">
                                        <p style="color: #155724; margin: 0; font-size: 15px;">
                                            ✅ <strong>測試成功！</strong><br>
                                            當真實跌倒發生時，您將收到類似格式的緊急警示郵件，包含：
                                        </p>
                                        <ul style="color: #155724; margin: 10px 0 0 20px; padding: 0; font-size: 14px;">
                                            <li>跌倒發生的精確時間</li>
                                            <li>跌倒信心度與衝擊力數據</li>
                                            <li>即時 GPS 位置（經緯度）</li>
                                            <li>Google 地圖連結</li>
                                        </ul>
                                    </div>
                                </td>
                            </tr>
                            
                            <!-- 頁尾 -->
                            <tr>
                                <td style="padding: 20px 30px; background-color: #f8f9fa; border-radius: 0 0 12px 12px; text-align: center;">
                                    <p style="color: #999999; margin: 0 0 10px 0; font-size: 13px;">
                                        此郵件由 FallDetect 跌倒偵測系統自動發送
                                    </p>
                                    <p style="color: #999999; margin: 0; font-size: 12px;">
                                        請勿直接回覆此郵件
                                    </p>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </body>
        </html>
        """
    }
}
