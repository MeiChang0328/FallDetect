//
//  StatCard.swift
//  FallDetect
//
//  Created on 2025/12/16.
//  可重用的統計數據卡片元件
//

import SwiftUI

/// 統計數據卡片元件
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String?
    let color: Color
    let style: StatCardStyle
    
    init(
        icon: String,
        title: String,
        value: String,
        unit: String? = nil,
        color: Color = .appPrimary,
        style: StatCardStyle = .compact
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.unit = unit
        self.color = color
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .compact:
            compactCard
        case .expanded:
            expandedCard
        case .minimal:
            minimalCard
        }
    }
    
    // MARK: - Compact Style (用於列表)
    
    private var compactCard: some View {
        HStack(spacing: 12) {
            // 圖示
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            // 內容
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.appNumberMini)
                        .foregroundColor(.appTextPrimary)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.appShadowLight, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Expanded Style (用於主要顯示)
    
    private var expandedCard: some View {
        VStack(spacing: 12) {
            // 圖示
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            // 標題
            Text(title)
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
            
            // 數值
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.appNumberSmall)
                    .foregroundColor(.appTextPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(.appBodySecondary)
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.appShadowMedium, radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Minimal Style (用於網格佈局)
    
    private var minimalCard: some View {
        VStack(spacing: 8) {
            // 標題 + 圖示
            HStack {
                Text(title)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            // 數值
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.appNumberMini)
                    .foregroundColor(.appTextPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(.appCaption2)
                        .foregroundColor(.appTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.appShadowLight, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Style Enum

enum StatCardStyle {
    case compact    // 緊湊型（橫向）
    case expanded   // 展開型（直向，主要顯示）
    case minimal    // 極簡型（小卡片）
}

// MARK: - 預設值擴展

extension StatCard {
    /// 步數卡片
    static func steps(_ value: String) -> StatCard {
        StatCard(
            icon: "figure.walk",
            title: "步數",
            value: value,
            unit: "步",
            color: .appPrimary,
            style: .compact
        )
    }
    
    /// 時間卡片
    static func duration(_ value: String) -> StatCard {
        StatCard(
            icon: "clock",
            title: "時間",
            value: value,
            color: .appSecondary,
            style: .compact
        )
    }
    
    /// 步頻卡片
    static func cadence(_ value: String) -> StatCard {
        StatCard(
            icon: "gauge",
            title: "步頻",
            value: value,
            unit: "步/分",
            color: .appSuccess,
            style: .compact
        )
    }
    
    /// 距離卡片
    static func distance(_ value: String) -> StatCard {
        StatCard(
            icon: "map",
            title: "距離",
            value: value,
            unit: "公里",
            color: .appWarning,
            style: .compact
        )
    }
    
    /// 跌倒事件卡片
    static func fallEvents(_ value: String) -> StatCard {
        StatCard(
            icon: "exclamationmark.triangle.fill",
            title: "跌倒事件",
            value: value,
            unit: "次",
            color: .appDanger,
            style: .compact
        )
    }
}

// MARK: - 預覽

#Preview("Compact Style") {
    VStack(spacing: 12) {
        StatCard.steps("2,500")
        StatCard.duration("00:25:34")
        StatCard.cadence("128")
        StatCard.distance("1.75")
        StatCard.fallEvents("2")
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Expanded Style") {
    HStack(spacing: 12) {
        StatCard(
            icon: "figure.walk",
            title: "總步數",
            value: "2,500",
            unit: "步",
            color: .appPrimary,
            style: .expanded
        )
        
        StatCard(
            icon: "clock",
            title: "跑步時間",
            value: "25:34",
            color: .appSecondary,
            style: .expanded
        )
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Minimal Style") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatCard(icon: "figure.walk", title: "步數", value: "2,500", unit: "步", color: .appPrimary, style: .minimal)
        StatCard(icon: "clock", title: "時間", value: "25:34", color: .appSecondary, style: .minimal)
        StatCard(icon: "gauge", title: "步頻", value: "128", unit: "步/分", color: .appSuccess, style: .minimal)
        StatCard(icon: "map", title: "距離", value: "1.75", unit: "km", color: .appWarning, style: .minimal)
    }
    .padding()
    .background(Color.appBackground)
}
