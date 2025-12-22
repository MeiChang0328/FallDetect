//
//  Typography.swift
//  FallDetect
//
//  Created on 2025/12/16.
//  設計系統 - 字體系統
//

import SwiftUI

/// FallDetect 應用程式的字體系統
extension Font {
    // MARK: - 標題字體（SF Pro Display）
    
    /// 大標題（48pt, Bold）
    static let appLargeTitle = Font.system(size: 48, weight: .bold, design: .default)
    
    /// 標題 1（34pt, Bold）
    static let appTitle1 = Font.system(size: 34, weight: .bold, design: .default)
    
    /// 標題 2（28pt, Bold）
    static let appTitle2 = Font.system(size: 28, weight: .bold, design: .default)
    
    /// 標題 3（22pt, Semibold）
    static let appTitle3 = Font.system(size: 22, weight: .semibold, design: .default)
    
    // MARK: - 內文字體（SF Pro Text）
    
    /// 主要內文（17pt, Regular）
    static let appBody = Font.system(size: 17, weight: .regular, design: .default)
    
    /// 次要內文（15pt, Regular）
    static let appBodySecondary = Font.system(size: 15, weight: .regular, design: .default)
    
    /// 小內文（13pt, Regular）
    static let appCaption = Font.system(size: 13, weight: .regular, design: .default)
    
    /// 極小內文（11pt, Regular）
    static let appCaption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // MARK: - 數字字體（SF Pro Rounded）
    
    /// 大數字（70pt, Bold, Rounded）- 用於主要統計數據
    static let appNumberLarge = Font.system(size: 70, weight: .bold, design: .rounded)
    
    /// 中等數字（36pt, Semibold, Rounded）- 用於次要統計數據
    static let appNumberMedium = Font.system(size: 36, weight: .semibold, design: .rounded)
    
    /// 小數字（24pt, Semibold, Rounded）- 用於卡片數據
    static let appNumberSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    /// 迷你數字（18pt, Medium, Rounded）- 用於標籤數據
    static let appNumberMini = Font.system(size: 18, weight: .medium, design: .rounded)
    
    // MARK: - 按鈕字體
    
    /// 主要按鈕（17pt, Bold）
    static let appButtonPrimary = Font.system(size: 17, weight: .bold, design: .default)
    
    /// 次要按鈕（15pt, Semibold）
    static let appButtonSecondary = Font.system(size: 15, weight: .semibold, design: .default)
    
    /// 小按鈕（13pt, Medium）
    static let appButtonSmall = Font.system(size: 13, weight: .medium, design: .default)
    
    // MARK: - 特殊字體
    
    /// 等寬字體（用於時間、代碼）
    static let appMonospaced = Font.system(size: 17, design: .monospaced)
    
    /// 等寬數字字體（大）
    static let appMonospacedLarge = Font.system(size: 70, weight: .bold, design: .monospaced)
}

// MARK: - 文字樣式

extension View {
    /// 應用主標題樣式
    func appTitleStyle() -> some View {
        self
            .font(.appTitle1)
            .foregroundColor(.appTextPrimary)
    }
    
    /// 應用副標題樣式
    func appSubtitleStyle() -> some View {
        self
            .font(.appTitle3)
            .foregroundColor(.appTextSecondary)
    }
    
    /// 應用主要內文樣式
    func appBodyStyle() -> some View {
        self
            .font(.appBody)
            .foregroundColor(.appTextPrimary)
    }
    
    /// 應用次要內文樣式
    func appBodySecondaryStyle() -> some View {
        self
            .font(.appBodySecondary)
            .foregroundColor(.appTextSecondary)
    }
    
    /// 應用標籤樣式
    func appCaptionStyle() -> some View {
        self
            .font(.appCaption)
            .foregroundColor(.appTextSecondary)
    }
}

// MARK: - 預覽

#if DEBUG
struct Typography_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Group {
                    Text("標題字體")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Large Title")
                        .font(.appLargeTitle)
                    Text("Title 1")
                        .font(.appTitle1)
                    Text("Title 2")
                        .font(.appTitle2)
                    Text("Title 3")
                        .font(.appTitle3)
                }
                
                Divider()
                
                Group {
                    Text("內文字體")
                        .font(.headline)
                    
                    Text("Body - 這是主要內文字體，用於一般內容")
                        .font(.appBody)
                    Text("Body Secondary - 這是次要內文字體")
                        .font(.appBodySecondary)
                    Text("Caption - 這是小標籤字體")
                        .font(.appCaption)
                    Text("Caption 2 - 這是極小標籤字體")
                        .font(.appCaption2)
                }
                
                Divider()
                
                Group {
                    Text("數字字體")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("2,500")
                                .font(.appNumberLarge)
                            Text("Large")
                                .font(.appCaption)
                                .foregroundColor(.appTextSecondary)
                        }
                        
                        VStack {
                            Text("128")
                                .font(.appNumberMedium)
                            Text("Medium")
                                .font(.appCaption)
                                .foregroundColor(.appTextSecondary)
                        }
                        
                        VStack {
                            Text("42")
                                .font(.appNumberSmall)
                            Text("Small")
                                .font(.appCaption)
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
                
                Divider()
                
                Group {
                    Text("按鈕字體")
                        .font(.headline)
                    
                    VStack(spacing: 10) {
                        Text("Primary Button")
                            .font(.appButtonPrimary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.appPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        
                        Text("Secondary Button")
                            .font(.appButtonSecondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color.appSecondary.opacity(0.1))
                            .foregroundColor(.appSecondary)
                            .cornerRadius(8)
                        
                        Text("Small Button")
                            .font(.appButtonSmall)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.appBackground)
                            .foregroundColor(.appTextSecondary)
                            .cornerRadius(6)
                    }
                }
                
                Divider()
                
                Group {
                    Text("特殊字體")
                        .font(.headline)
                    
                    Text("00:25:34")
                        .font(.appMonospacedLarge)
                    Text("Monospaced 用於時間顯示")
                        .font(.appMonospaced)
                }
            }
            .padding()
        }
    }
}
#endif
