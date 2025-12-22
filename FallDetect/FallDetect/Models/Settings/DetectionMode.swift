//
//  DetectionMode.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/16.
//

import Foundation

/// 跌倒偵測模式
enum DetectionMode: String, CaseIterable, Codable {
    case conservative = "conservative"  // 保守模式
    case balanced = "balanced"          // 平衡模式
    case sensitive = "sensitive"        // 敏感模式
    
    /// 顯示名稱
    var displayName: String {
        switch self {
        case .conservative:
            return "保守模式"
        case .balanced:
            return "平衡模式"
        case .sensitive:
            return "敏感模式"
        }
    }
    
    /// 模式描述
    var description: String {
        switch self {
        case .conservative:
            return "減少誤報，適合日常高活動量使用者"
        case .balanced:
            return "平衡準確度與敏感度，適合一般使用"
        case .sensitive:
            return "提高偵測率，適合測試與高風險使用者（推薦）"
        }
    }
    
    /// 圖示名稱
    var iconName: String {
        switch self {
        case .conservative:
            return "shield.fill"
        case .balanced:
            return "scale.3d"
        case .sensitive:
            return "bolt.fill"
        }
    }
    
    /// 建議使用者類型
    var recommendedFor: String {
        switch self {
        case .conservative:
            return "運動員、高活動量使用者"
        case .balanced:
            return "一般成年人"
        case .sensitive:
            return "老年人、高風險使用者、測試環境"
        }
    }
}
