//
//  ColorScheme.swift
//  FallDetect
//
//  Created on 2025/12/16.
//  設計系統 - 色彩方案
//

import SwiftUI

/// FallDetect 應用程式的色彩方案
extension Color {
    // MARK: - 主要色彩
    
    /// 主色（藍色）- 用於主要操作、連結、選中狀態
    static let appPrimary = Color(hex: "4A90E2")
    
    /// 輔助色（紫色）- 用於次要操作、強調元素
    static let appSecondary = Color(hex: "9B59B6")
    
    // MARK: - 狀態色彩
    
    /// 成功色（綠色）- 用於成功訊息、正面狀態
    static let appSuccess = Color(hex: "2ECC71")
    
    /// 警告色（橙色）- 用於警告訊息、需要注意的狀態
    static let appWarning = Color(hex: "F39C12")
    
    /// 危險色（紅色）- 用於錯誤訊息、跌倒警告、刪除操作
    static let appDanger = Color(hex: "E74C3C")
    
    // MARK: - 中性色彩
    
    /// 深色文字（接近黑色）
    static let appTextPrimary = Color(hex: "2C3E50")
    
    /// 中等文字（灰色）
    static let appTextSecondary = Color(hex: "7F8C8D")
    
    /// 淺色文字（淺灰）
    static let appTextTertiary = Color(hex: "BDC3C7")
    
    /// 背景色（極淺灰）
    static let appBackground = Color(hex: "F8F9FA")
    
    /// 卡片背景（白色）
    static let appCardBackground = Color.white
    
    /// 分隔線
    static let appDivider = Color(hex: "ECF0F1")
    
    // MARK: - 漸變色彩
    
    /// 主要漸變（藍色到紫色）
    static let appGradientPrimary = LinearGradient(
        colors: [appPrimary, appSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 成功漸變（綠色系）
    static let appGradientSuccess = LinearGradient(
        colors: [Color(hex: "56CCF2"), appSuccess],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 警告漸變（橙色到紅色）
    static let appGradientWarning = LinearGradient(
        colors: [appWarning, Color(hex: "E67E22")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 危險漸變（紅色系）
    static let appGradientDanger = LinearGradient(
        colors: [Color(hex: "FC466B"), appDanger],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 陰影色彩
    
    /// 淺陰影
    static let appShadowLight = Color.black.opacity(0.05)
    
    /// 中等陰影
    static let appShadowMedium = Color.black.opacity(0.1)
    
    /// 深陰影
    static let appShadowDark = Color.black.opacity(0.2)
    
    // MARK: - Hex 初始化器
    
    /// 從十六進制字串初始化顏色
    /// - Parameter hex: 十六進制顏色字串（例如："4A90E2" 或 "#4A90E2"）
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 預覽

#if DEBUG
struct ColorScheme_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                Group {
                    Text("主要色彩")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        ColorSwatch(color: .appPrimary, name: "Primary")
                        ColorSwatch(color: .appSecondary, name: "Secondary")
                    }
                }
                
                Group {
                    Text("狀態色彩")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        ColorSwatch(color: .appSuccess, name: "Success")
                        ColorSwatch(color: .appWarning, name: "Warning")
                        ColorSwatch(color: .appDanger, name: "Danger")
                    }
                }
                
                Group {
                    Text("中性色彩")
                        .font(.headline)
                    
                    VStack(spacing: 10) {
                        HStack(spacing: 15) {
                            ColorSwatch(color: .appTextPrimary, name: "Text Primary")
                            ColorSwatch(color: .appTextSecondary, name: "Text Secondary")
                        }
                        HStack(spacing: 15) {
                            ColorSwatch(color: .appBackground, name: "Background")
                            ColorSwatch(color: .appDivider, name: "Divider")
                        }
                    }
                }
                
                Group {
                    Text("漸變色彩")
                        .font(.headline)
                    
                    VStack(spacing: 10) {
                        Rectangle()
                            .fill(Color.appGradientPrimary)
                            .frame(height: 60)
                            .cornerRadius(8)
                            .overlay(Text("Primary Gradient").foregroundColor(.white))
                        
                        Rectangle()
                            .fill(Color.appGradientSuccess)
                            .frame(height: 60)
                            .cornerRadius(8)
                            .overlay(Text("Success Gradient").foregroundColor(.white))
                        
                        Rectangle()
                            .fill(Color.appGradientDanger)
                            .frame(height: 60)
                            .cornerRadius(8)
                            .overlay(Text("Danger Gradient").foregroundColor(.white))
                    }
                }
            }
            .padding()
        }
    }
}

struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
        }
    }
}
#endif
