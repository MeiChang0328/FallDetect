# FallDetect App 專案重構規格書

## 📋 專案概述
**專案名稱**: FallDetect - 跑步追蹤與跌倒偵測應用程式  
**當前版本**: 1.0  
**目標版本**: 2.0  
**更新日期**: 2025年12月16日

---

## 🛠️ 技術棧規範

### 核心技術
- **語言**: Swift 5.9+
- **UI 框架**: SwiftUI
- **資料持久化**: SwiftData（取代 UserDefaults + Codable）
- **最低支援版本**: iOS 17.0+, macOS 14.0+

### 必要框架 (Apple 原生)
```swift
// UI & App 架構
import SwiftUI
import SwiftData

// 感測器與定位
import CoreMotion          // 加速度計、陀螺儀、步數
import CoreLocation        // GPS 定位

// 觸覺回饋
import CoreHaptics         // 進階觸覺回饋
import UIKit              // UIImpactFeedbackGenerator

// 音訊
import AVFoundation        // 音訊播放、音訊 Session
import AudioToolbox        // 系統音效

// 網路
import Foundation          // URLSession, JSONEncoder/Decoder

// 安全儲存
import Security            // Keychain API（儲存 API Key）

// 分享功能（選配）
import Social              // 社群分享（Phase 5）
```

### 第三方依賴
**原則**: 最小化依賴，優先使用原生框架

```swift
// ❌ 不使用以下框架：
// - Alamofire (改用 URLSession)
// - SwiftyJSON (改用 Codable)
// - Realm (改用 SwiftData)
// - Charts (考慮使用 Swift Charts 或自建)

// ✅ 可選第三方框架（按需評估）：
// - Swift Charts (Apple 官方，iOS 16+)
// - Lottie (動畫，若需要複雜動畫)
```

### SwiftData 遷移策略
**從 UserDefaults + Codable → SwiftData**

**優點**：
- ✅ 原生支援，無需第三方依賴
- ✅ 自動持久化，減少樣板程式碼
- ✅ 支援關聯、查詢、排序
- ✅ 與 SwiftUI 深度整合（@Query）
- ✅ iCloud 同步支援（可選）

**遷移項目**：
```swift
// 現有 Codable 模型 → SwiftData @Model
1. RunRecord        → @Model class RunRecord
2. Settings         → @Model class Settings
3. (新) FallEvent   → @Model class FallEvent

// 現有 Store → SwiftData ModelContext
1. RunRecordStore   → 使用 @Query + ModelContext
2. (新) FallEventStore → 使用 @Query + ModelContext
```

---

## 🎯 變更目標

### 1. UI/UX 美化升級

#### 1.1 SwiftUI 現代化設計
**使用 SwiftUI 最佳實踐**：
- `@Observable` macro（iOS 17+）取代 `ObservableObject`
- `@Query` 直接查詢 SwiftData
- `#Preview` macro 取代 `#Preview`
- `@Environment(\.modelContext)` 注入資料庫

**設計系統建立**
- **色彩系統**
  - 主色調：使用漸層色彩（藍色 → 紫色）
  - 強調色：綠色（開始）、紅色（停止/警告）、橙色（測試）
  - 背景色：深色模式支援，使用磨砂玻璃效果
  - 文字層級：標題/正文/輔助文字的色彩對比度優化

- **間距與排版**
  - 統一 padding 規範：8pt, 12pt, 16pt, 20pt, 24pt
  - 卡片化設計：所有資訊區塊改為卡片式呈現
  - 圓角統一：12pt (按鈕/卡片)

- **動畫效果**
  - 頁面切換：淡入淡出動畫
  - 按鈕互動：彈跳效果 (spring animation)
  - 數據更新：數字漸變動畫
  - 跌倒警告：脈衝閃爍動畫

#### 1.2 各頁面美化細節

**RunTrackingView（跑步追蹤頁）**
```swift
改進項目：
1. 頂部狀態列 → 改為磨砂玻璃背景卡片
2. 時間顯示 → 加入漸層文字效果
3. 步數/步頻 → 圓形進度環視覺化
4. 節拍器控制 → 改為滑桿 + 預設 BPM 快捷按鈕 (160, 170, 180)
5. 位置資訊 → 改為展開式卡片，整合地圖預覽
6. 感測器數據 → 改為圖表視覺化（折線圖）
7. 開始/停止按鈕 → 大型圓形按鈕，中央懸浮設計
8. 背景 → 漸層色彩，隨跑步狀態變化
```

**HistoryView（歷史記錄頁）**
```swift
改進項目：
1. 空狀態 → 加入插圖、引導動畫
2. 列表項目 → 卡片式設計，加入陰影效果
3. 統計圖表 → 新增週/月統計圖表
4. 搜尋/篩選 → 加入日期範圍篩選功能
5. 刪除動作 → 滑動刪除動畫優化
```

**SettingsView（設定頁）**
```swift
改進項目：
1. 分組樣式 → 改為卡片式分組
2. Toggle 開關 → 自訂顏色與動畫
3. Email 輸入 → 加入驗證提示與圖示
4. 新增 SendGrid API Key 設定區域
5. 新增通知測試按鈕
6. 關於區域 → 加入 Logo、版本資訊、授權許可
```

**MetronomeView（節拍器頁）**
```swift
改進項目：
1. BPM 數字 → 改為圓形進度環視覺化
2. 加減按鈕 → 改為滑桿控制
3. 預設 BPM → 新增快捷按鈕 (120, 140, 160, 180)
4. 節拍視覺化 → 加入脈衝動畫指示器
5. 音效選擇 → 新增多種音效選項（木魚、節拍器、鼓聲）
```

**RunSummaryView（跑步總結頁）**
```swift
改進項目：
1. 總結卡片 → 漸層背景卡片
2. 數據呈現 → 加入圖示、進度條
3. 分享功能 → 新增分享至社群媒體按鈕
4. 地圖路線 → 加入路線地圖視覺化（若有位置記錄）
```

#### 1.3 圖示與插圖
- 使用 SF Symbols 3.0+ 新圖示
- 空狀態插圖設計（可使用 unDraw 或自訂 SVG）
- 加入品牌 Logo 設計

#### 1.4 Dark Mode 支援
- 所有顏色支援深色模式自動切換
- 確保對比度符合 WCAG AA 標準

---

### 2. 跌倒偵測演算法優化（高靈敏度模式）

#### 2.1 目前問題分析
**現況：**
- 閾值設定已經很敏銳（0.5G 衝擊、0.05G 自由落體）
- 四階段狀態機嚴謹但可能造成漏報
- 冷卻時間 5 秒可能錯過連續跌倒

**調整目標：**
讓演算法更容易觸發，提高偵測率，減少漏報（False Negative）

#### 2.2 演算法調整方向

**A. 閾值降低與彈性化**
```swift
改進措施：
1. 衝擊閾值：0.5G → 0.3G（更敏感）
2. 自由落體閾值：0.05G → 0.1G（放寬範圍）
3. 自由落體時間：50ms → 30ms（更快觸發）
4. 靜止閾值：0.05G → 0.15G（允許微小移動）
5. 靜止時間：0.3秒 → 0.2秒（更快判定）
6. 旋轉閾值：0.3 rad/s → 0.2 rad/s（更容易偵測）
7. 冷卻時間：5秒 → 3秒（更頻繁偵測）
```

**優化後的閾值配置：**
```swift
// 超高靈敏度配置（容易觸發模式）
private let impactThreshold: Double = 0.3        // 降低衝擊閾值
private let freefallThreshold: Double = 0.1      // 放寬自由落體範圍
private let freefallDuration: TimeInterval = 0.03 // 30毫秒即可
private let postImpactThreshold: Double = 0.15   // 允許輕微移動
private let postImpactDuration: TimeInterval = 0.2 // 快速判定
private let rotationThreshold: Double = 0.2      // 更敏感的旋轉偵測
private let cooldownPeriod: TimeInterval = 3.0   // 縮短冷卻時間
```

**B. 簡化狀態機邏輯**
```swift
改進措施：
1. 允許跳過自由落體階段（直接從正常 → 衝擊）
2. 減少必要條件組合（OR 邏輯取代 AND 邏輯）
3. 新增「可疑動作」中間狀態，累積信心度
```

**新增三級偵測模式：**
```swift
enum DetectionMode {
    case conservative  // 保守模式（原始設定，減少誤報）
    case balanced      // 平衡模式（預設，適中）
    case sensitive     // 敏感模式（容易觸發，適合測試與高風險使用者）
}

// 在 Settings 中新增模式選擇
@Published var fallDetectionMode: DetectionMode = .sensitive
```

**C. 多重觸發條件（OR 邏輯）**
```swift
確認跌倒的條件（滿足任一即觸發）：
1. 高衝擊 + 短暫靜止（原有邏輯）
2. 中等衝擊 + 旋轉 + 姿態變化
3. 持續自由落體 (>100ms) + 任何衝擊
4. 劇烈旋轉 (>1.0 rad/s) + 加速度變化
5. Z軸姿態角突變 (>45度) + 衝擊
6. 連續多次中等衝擊（1秒內 ≥ 2次）
```

**D. 姿態角度分析強化**
```swift
新增判斷邏輯：
- 偵測裝置從直立 → 水平的快速轉變
- Roll/Pitch 角度突變超過 45 度
- 手機從口袋/手上 → 地面的典型動作模式
```

**實作範例：**
```swift
private func analyzeAttitudeChange(attitude: CMAttitude) {
    let currentRoll = abs(attitude.roll)
    let currentPitch = abs(attitude.pitch)
    
    // 檢查是否從直立變為水平
    if let lastAttitude = previousAttitude {
        let rollChange = abs(currentRoll - lastAttitude.roll)
        let pitchChange = abs(currentPitch - lastAttitude.pitch)
        
        // 任一軸向變化超過 45 度（0.785 弧度）
        if rollChange > 0.785 || pitchChange > 0.785 {
            attitudeChangeDetected = true
            print("📐 偵測到姿態突變: Roll=\(rollChange), Pitch=\(pitchChange)")
        }
    }
    previousAttitude = attitude
}
```

**E. 累積信心度系統**
```swift
改進措施：
- 不再要求「一次完整的四階段流程」
- 持續累積可疑行為的信心度
- 信心度達 60% 即觸發警告（原為需完整四階段）
```

**信心度計算：**
```swift
private func calculateConfidence() -> Double {
    var confidence: Double = 0.0
    
    // 基礎分數
    if hasFreefallDetected { confidence += 0.2 }
    if hasImpactDetected { confidence += 0.3 }
    if hasRotationDetected { confidence += 0.15 }
    if hasAttitudeChange { confidence += 0.2 }
    if hasPostImpactStillness { confidence += 0.15 }
    
    // 衝擊強度加成
    let impactBonus = min(0.3, (maxImpactMagnitude - 0.3) / 2.0 * 0.3)
    confidence += impactBonus
    
    return min(1.0, confidence)
}

// 觸發條件
if calculateConfidence() >= 0.6 { // 降低門檻：0.6 取代 0.8
    confirmFall()
}
```

**F. 時間窗口彈性化**
```swift
改進措施：
- 延長跌倒偵測的時間窗口：2秒 → 3秒
- 允許非連續的狀態組合（間隔允許 0.5 秒）
```

**G. 環境自適應學習（選配）**
```swift
進階功能：
- 記錄使用者的日常動作模式（走路、跑步、坐下）
- 建立個人化基準線
- 自動調整閾值以適應使用者的活動強度
```

#### 2.3 實作程式碼架構

**FallDetection.swift 重構：**
```swift
class FallDetection: ObservableObject {
    // ... 現有屬性 ...
    
    // 新增屬性
    @Published var detectionMode: DetectionMode = .sensitive
    private var previousAttitude: CMAttitude?
    private var attitudeChangeDetected: Bool = false
    private var recentImpacts: [Date] = [] // 記錄最近的衝擊時間
    
    // 可配置的閾值（根據模式動態調整）
    private var currentThresholds: DetectionThresholds {
        switch detectionMode {
        case .conservative:
            return DetectionThresholds.conservative
        case .balanced:
            return DetectionThresholds.balanced
        case .sensitive:
            return DetectionThresholds.sensitive
        }
    }
    
    // 主要分析方法（重構）
    func analyzeMotion(
        acceleration: CMAcceleration,
        rotationRate: CMRotationRate,
        attitude: CMAttitude
    ) {
        // 1. 冷卻期檢查
        if isInCooldown() { return }
        
        // 2. 基礎數據計算
        let totalAcceleration = calculateTotalAcceleration(acceleration)
        let totalRotation = calculateTotalRotation(rotationRate)
        
        // 3. 多維度偵測（並行）
        let impactDetected = detectImpact(totalAcceleration)
        let freefallDetected = detectFreefall(totalAcceleration)
        let rotationDetected = detectRotation(totalRotation)
        let attitudeChanged = detectAttitudeChange(attitude)
        
        // 4. 累積證據
        updateEvidence(
            impact: impactDetected,
            freefall: freefallDetected,
            rotation: rotationDetected,
            attitudeChange: attitudeChanged
        )
        
        // 5. 計算信心度
        let confidence = calculateConfidence()
        
        // 6. 觸發判斷（降低門檻）
        if confidence >= currentThresholds.confirmationThreshold {
            confirmFall(confidence: confidence)
        }
    }
}

struct DetectionThresholds {
    let impactThreshold: Double
    let freefallThreshold: Double
    let rotationThreshold: Double
    let attitudeChangeThreshold: Double
    let confirmationThreshold: Double
    let cooldownPeriod: TimeInterval
    
    static let conservative = DetectionThresholds(
        impactThreshold: 0.8,
        freefallThreshold: 0.05,
        rotationThreshold: 0.5,
        attitudeChangeThreshold: 1.0,
        confirmationThreshold: 0.8,
        cooldownPeriod: 5.0
    )
    
    static let balanced = DetectionThresholds(
        impactThreshold: 0.5,
        freefallThreshold: 0.08,
        rotationThreshold: 0.3,
        attitudeChangeThreshold: 0.785,
        confirmationThreshold: 0.7,
        cooldownPeriod: 4.0
    )
    
    static let sensitive = DetectionThresholds(
        impactThreshold: 0.3,      // 極易觸發
        freefallThreshold: 0.1,
        rotationThreshold: 0.2,
        attitudeChangeThreshold: 0.6,
        confirmationThreshold: 0.6, // 60% 信心度即觸發
        cooldownPeriod: 3.0
    )
}
```

#### 2.4 UI 變更

**SettingsView 新增偵測模式選擇：**
```swift
Section(header: Text("跌倒偵測靈敏度")) {
    Picker("偵測模式", selection: $settings.fallDetectionMode) {
        Text("保守模式").tag(DetectionMode.conservative)
        Text("平衡模式").tag(DetectionMode.balanced)
        Text("敏感模式（推薦）").tag(DetectionMode.sensitive)
    }
    .pickerStyle(.segmented)
    
    // 模式說明
    switch settings.fallDetectionMode {
    case .conservative:
        Text("減少誤報，適合日常高活動量使用者")
    case .balanced:
        Text("平衡準確度與敏感度")
    case .sensitive:
        Text("提高偵測率，適合測試與高風險使用者")
    }
    .font(.caption)
    .foregroundColor(.secondary)
}

Section(header: Text("偵測狀態（即時）")) {
    HStack {
        Text("當前信心度")
        Spacer()
        Text("\(Int(fallDetection.fallConfidence * 100))%")
            .foregroundColor(
                fallDetection.fallConfidence > 0.6 ? .red : 
                fallDetection.fallConfidence > 0.3 ? .orange : .green
            )
    }
    
    // 信心度進度條
    ProgressView(value: fallDetection.fallConfidence)
        .tint(fallDetection.fallConfidence > 0.6 ? .red : .blue)
}
```

#### 2.5 測試與驗證

**測試場景：**
```
1. 輕度測試：
   - 手機從腰部高度掉落到沙發 ✓ 應觸發
   - 快速坐下動作 ✓ 應觸發
   - 手機從桌上滑落 ✓ 應觸發

2. 中度測試：
   - 慢跑時突然蹲下 ✓ 應觸發
   - 手機從口袋掉出 ✓ 應觸發
   - 快速轉身動作 ✓ 可能觸發

3. 日常動作（不應觸發）：
   - 正常走路 ✗
   - 坐下/站起 ✗（敏感模式可能觸發）
   - 上下樓梯 ✗
```

**調整策略：**
- 如果誤報過多 → 提高 `confirmationThreshold` 至 0.65
- 如果漏報過多 → 降低 `impactThreshold` 至 0.25
- 根據使用者回饋動態調整

#### 2.6 預期效果

**調整前（現況）：**
- 觸發門檻：高（需完整四階段）
- 偵測率：~70%
- 誤報率：~5%

**調整後（敏感模式）：**
- 觸發門檻：低（60% 信心度即可）
- 預期偵測率：~90%+
- 預期誤報率：~15-20%（可接受範圍）

**取捨考量：**
- 跌倒偵測系統寧願「過度警告」也不能「漏報」
- 敏感模式適合高風險使用者（老年人、患者）
- 使用者可根據需求選擇模式

---

### 3. SendGrid API 整合

#### 2.1 架構變更

**移除項目**
```swift
- MessageUI 框架依賴
- MFMailComposeViewController 相關程式碼
- EmailService 中的手動寄信邏輯
```

**新增項目**
```swift
1. SendGridService.swift - SendGrid API 服務類別
2. EmailTemplate.swift - Email 範本管理
3. NetworkManager.swift - 網路請求管理
4. Settings 擴充 - 新增 SendGrid API Key 儲存
```

#### 3.2 SendGrid 整合細節

**SendGridService.swift 架構**
```swift
class SendGridService {
    // 單例模式
    static let shared = SendGridService()
    
    // API 設定
    private let apiEndpoint = "https://api.sendgrid.com/v3/mail/send"
    private var apiKey: String {
        return Settings.shared.sendGridAPIKey
    }
    
    // 主要方法
    func sendFallAlertEmail(
        to: String,
        userName: String?,
        location: String?,
        timestamp: Date,
        confidence: Double,
        completion: @escaping (Result<Void, Error>) -> Void
    )
    
    func sendTestEmail(
        to: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
    
    // 私有輔助方法
    private func buildEmailPayload(...) -> [String: Any]
    private func sendRequest(payload: [String: Any], completion: ...)
}
```

**Email 範本設計**
```html
跌倒警告 Email 內容：
- 標題：🚨 跌倒偵測警告 - 緊急通知
- 內容：
  1. 警告橫幅（紅色背景）
  2. 偵測時間
  3. 信心度（百分比）
  4. 位置資訊（含 Google Maps 連結）
  5. 建議行動
  6. 聯絡資訊
  7. 應用程式資訊
- 格式：HTML 格式，響應式設計
```

#### 2.3 Settings 擴充

**新增設定項目**
```swift
class Settings: ObservableObject {
    // 現有項目
    @Published var isFallDetectionEnabled: Bool
    @Published var emergencyEmail: String
    
    // 新增項目
    @Published var sendGridAPIKey: String
    @Published var senderEmail: String // SendGrid 驗證的發件人 Email
    @Published var senderName: String // 發件人名稱
    @Published var enableEmailNotifications: Bool
    @Published var lastEmailSentDate: Date?
    
    // Email 發送頻率限制（避免頻繁發送）
    var canSendEmail: Bool {
        guard let lastSent = lastEmailSentDate else { return true }
        return Date().timeIntervalSince(lastSent) > 300 // 5分鐘冷卻
    }
}
```

#### 2.4 錯誤處理

**錯誤類型定義**
```swift
enum SendGridError: LocalizedError {
    case invalidAPIKey
    case invalidEmail
    case networkError(Error)
    case rateLimitExceeded
    case serverError(statusCode: Int)
    case missingConfiguration
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "SendGrid API Key 無效或未設定"
        case .invalidEmail:
            return "Email 地址格式不正確"
        case .networkError(let error):
            return "網路錯誤：\(error.localizedDescription)"
        case .rateLimitExceeded:
            return "發送頻率過高，請稍後再試"
        case .serverError(let code):
            return "伺服器錯誤 (代碼: \(code))"
        case .missingConfiguration:
            return "請先在設定中配置 SendGrid API Key"
        }
    }
}
```

#### 2.5 UI 變更

**SettingsView 新增區域**
```swift
Section(header: Text("SendGrid Email 設定")) {
    // API Key 輸入（安全顯示）
    SecureField("SendGrid API Key", text: $settings.sendGridAPIKey)
    
    // 發件人資訊
    TextField("發件人 Email", text: $settings.senderEmail)
    TextField("發件人名稱", text: $settings.senderName)
    
    // 測試按鈕
    Button("發送測試郵件") {
        testSendGridConnection()
    }
    
    // 說明文字
    Text("請至 SendGrid 官網申請免費 API Key")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

**RunTrackingView 修改**
```swift
// 移除 MFMailComposeViewController 相關程式碼
// 修改 sendFallAlertEmail() 方法

private func sendFallAlertEmail() {
    guard settings.enableEmailNotifications else { return }
    guard settings.canSendEmail else {
        showMessage("發送頻率過高，請稍後再試")
        return
    }
    
    SendGridService.shared.sendFallAlertEmail(
        to: settings.emergencyEmail,
        userName: nil,
        location: locationManager.locationString,
        timestamp: Date(),
        confidence: fallDetection.fallConfidence
    ) { result in
        DispatchQueue.main.async {
            switch result {
            case .success:
                print("✅ 警告郵件已成功發送")
                settings.lastEmailSentDate = Date()
            case .failure(let error):
                print("❌ 郵件發送失敗：\(error.localizedDescription)")
                // 顯示錯誤提示給使用者
            }
        }
    }
}
```

---

## 📁 重構後的檔案結構

### 目標：按功能模組化組織，提升可維護性

```
FallDetect/
├── FallDetect.xcodeproj/
└── FallDetect/
    │
    ├── 📱 App/
    │   ├── FallDetectApp.swift          # App 進入點
    │   └── ContentView.swift             # 測試用主視圖（可選保留）
    │
    ├── 🎨 Views/
    │   │
    │   ├── Tracking/                     # 跑步追蹤相關視圖
    │   │   ├── RunTrackingView.swift     # 主追蹤介面
    │   │   ├── RunSummaryView.swift      # 跑步總結頁
    │   │   └── MetronomeView.swift       # 節拍器視圖
    │   │
    │   ├── History/                      # 歷史記錄相關視圖
    │   │   ├── HistoryView.swift         # 記錄列表
    │   │   ├── RecordDetailView.swift    # 記錄詳情
    │   │   └── StatisticsView.swift      # 📊 統計圖表（新增）
    │   │
    │   ├── Settings/                     # 設定相關視圖
    │   │   ├── SettingsView.swift        # 主設定頁
    │   │   ├── AboutView.swift           # ℹ️ 關於頁面（新增）
    │   │   └── APIConfigView.swift       # 🔑 API 設定頁（新增）
    │   │
    │   └── Components/                   # 共用 UI 元件
    │       ├── Cards/
    │       │   ├── GradientCard.swift    # 🎨 漸層卡片元件（新增）
    │       │   ├── InfoCard.swift        # 📋 資訊卡片（新增）
    │       │   └── StatCard.swift        # 📊 統計卡片（新增）
    │       ├── Charts/
    │       │   ├── LineChartView.swift   # 📈 折線圖（新增）
    │       │   └── BarChartView.swift    # 📊 長條圖（新增）
    │       ├── Progress/
    │       │   ├── ProgressRing.swift    # ⭕ 圓形進度環（新增）
    │       │   └── LinearProgress.swift  # ━ 線性進度條（新增）
    │       ├── Buttons/
    │       │   ├── PrimaryButton.swift   # 🔵 主要按鈕（新增）
    │       │   ├── SecondaryButton.swift # ⚪ 次要按鈕（新增）
    │       │   └── IconButton.swift      # 🔘 圖示按鈕（新增）
    │       └── Common/
    │           ├── SensorDataItem.swift  # 📡 感測器數據項目
    │           ├── EmptyStateView.swift  # 🗂️ 空狀態視圖（新增）
    │           └── LoadingView.swift     # ⏳ 載入視圖（新增）
    │
    ├── 🔧 Services/
    │   │
    │   ├── Email/                        # Email 服務模組
    │   │   ├── SendGridService.swift     # 📧 SendGrid API 服務（新增）
    │   │   ├── EmailTemplate.swift       # 📄 Email 範本管理（新增）
    │   │   ├── EmailValidator.swift      # ✅ Email 驗證工具（新增）
    │   │   └── EmailService.swift        # ⚠️ 舊版手動寄信服務（標記廢棄）
    │   │
    │   ├── Tracking/                     # 追蹤服務模組
    │   │   ├── RunTracker.swift          # ⏱️ 跑步追蹤器
    │   │   ├── LocationManager.swift     # 📍 位置管理器
    │   │   └── MotionManager.swift       # 📲 動作感測器管理器
    │   │
    │   ├── Detection/                    # 偵測演算法模組
    │   │   ├── FallDetection.swift       # 🚨 跌倒偵測核心
    │   │   ├── FallDetectionConfig.swift # ⚙️ 偵測配置（新增）
    │   │   └── DetectionThresholds.swift # 🎚️ 閾值定義（新增）
    │   │
    │   ├── Network/                      # 網路服務模組
    │   │   ├── NetworkManager.swift      # 🌐 網路請求管理（新增）
    │   │   ├── APIClient.swift           # 🔌 API 客戶端（新增）
    │   │   └── NetworkError.swift        # ⚠️ 網路錯誤定義（新增）
    │   │
    │   └── Audio/                        # 音訊服務模組（新增）
    │       ├── MetronomeService.swift    # 🎵 節拍器服務（從 Metronome 類別重構）
    │       └── SoundManager.swift        # 🔊 音效管理器（新增）
    │
    ├── 📦 Models/
    │   │
    │   ├── Domain/                       # 領域模型（SwiftData）
    │   │   ├── RunRecord.swift           # 🏃 跑步記錄模型（@Model）
    │   │   └── FallEvent.swift           # 🚨 跌倒事件模型（@Model，新增）
    │   │
    │   ├── Settings/                     # 設定模型（SwiftData）
    │   │   ├── AppSettings.swift         # ⚙️ App 設定（@Model，重構自 Settings.swift）
    │   │   └── DetectionMode.swift       # 🎚️ 偵測模式枚舉（新增）
    │   │
    │   ├── Network/                      # 網路請求/回應模型（Codable）
    │   │   ├── EmailPayload.swift        # 📧 Email 請求載荷（新增）
    │   │   ├── SendGridRequest.swift     # 📨 SendGrid 請求（新增）
    │   │   └── SendGridResponse.swift    # 📬 SendGrid 回應（新增）
    │   │
    │   └── UI/                           # UI 相關模型（Struct）
    │       ├── ChartDataPoint.swift      # 📊 圖表資料點（新增）
    │       └── StatisticItem.swift       # 📈 統計項目（新增）
    │
    ├── 💾 Database/
    │   ├── ModelContainer+Shared.swift   # 🗄️ SwiftData Container 配置（新增）
    │   └── PreviewContainer.swift        # 👁️ Preview 用 Container（新增）
    │
    ├── 🛠️ Utilities/
    │   │
    │   ├── Constants/                    # 常數定義
    │   │   ├── AppConstants.swift        # 🔢 App 常數（新增）
    │   │   ├── APIConstants.swift        # 🌐 API 常數（新增）
    │   │   └── ThresholdConstants.swift  # 🎚️ 閾值常數（新增）
    │   │
    │   ├── Extensions/                   # Swift 擴充
    │   │   ├── Color+Extension.swift     # 🎨 Color 擴充（新增）
    │   │   ├── Date+Extension.swift      # 📅 Date 擴充（新增）
    │   │   ├── Double+Extension.swift    # 🔢 Double 擴充（新增）
    │   │   └── View+Extension.swift      # 👁️ View 擴充（新增）
    │   │
    │   ├── Helpers/                      # 輔助工具
    │   │   ├── DateFormatter+Shared.swift # 📆 日期格式化（新增）
    │   │   ├── NumberFormatter+Shared.swift # 🔢 數字格式化（新增）
    │   │   └── KeychainHelper.swift      # 🔐 Keychain 存取（新增）
    │   │
    │   └── Validators/                   # 驗證工具
    │       ├── EmailValidator.swift      # ✉️ Email 驗證（新增）
    │       └── APIKeyValidator.swift     # 🔑 API Key 驗證（新增）
    │
    ├── 🎨 Design/
    │   ├── Theme/                        # 主題系統（新增）
    │   │   ├── ColorScheme.swift         # 🎨 色彩方案
    │   │   ├── Typography.swift          # 📝 字體系統（新增）
    │   │   ├── Spacing.swift             # 📏 間距系統（新增）
    │   │   └── Shadows.swift             # 🌑 陰影效果（新增）
    │   │
    │   └── Styles/                       # 樣式定義（新增）
    │       ├── ButtonStyles.swift        # 🔘 按鈕樣式
    │       ├── TextFieldStyles.swift     # 📝 文字欄位樣式
    │       └── CardStyles.swift          # 🃏 卡片樣式
    │
    └── 📂 Resources/
        │
        ├── Assets.xcassets/              # 圖片資源
        │   ├── Colors/                   # 🎨 色彩資源
        │   │   ├── Primary.colorset
        │   │   ├── Secondary.colorset
        │   │   └── Accent.colorset
        │   ├── Icons/                    # 🔣 自訂圖示
        │   └── AppIcon.appiconset/       # 📱 App 圖示
        │
        ├── Fonts/                        # 📝 自訂字體（選配）
        │   └── (字體檔案)
        │
        ├── Localizations/                # 🌍 本地化資源
        │   ├── en.lproj/
        │   │   └── Localizable.strings   # 英文翻譯（新增）
        │   └── zh-Hant.lproj/
        │       └── Localizable.strings   # 繁體中文翻譯（新增）
        │
        ├── EmailTemplates/               # 📧 Email 範本
        │   ├── FallAlert.html            # 🚨 跌倒警告範本（新增）
        │   └── TestEmail.html            # 🧪 測試郵件範本（新增）
        │
        └── Sounds/                       # 🔊 音效檔案（選配）
            ├── metronome_tick.wav        # 節拍器音效
            └── alert_sound.wav           # 警告音效
```

### 檔案遷移對照表

| 現有檔案 | 新位置 | 狀態 | 框架變更 |
|---------|--------|------|---------|
| `FallDetectApp.swift` | `App/FallDetectApp.swift` | 📂 移動 + ✏️ 重構 | 加入 SwiftData ModelContainer |
| `ContentView.swift` | `App/ContentView.swift` | 📂 移動 | - |
| `RunTrackingView.swift` | `Views/Tracking/RunTrackingView.swift` | 📂 移動 + ✏️ 重構 | 使用 @Query |
| `RunSummaryView.swift` | `Views/Tracking/RunSummaryView.swift` | 📂 移動 + ✏️ 重構 | 使用 ModelContext |
| `MetronomeView.swift` | `Views/Tracking/MetronomeView.swift` | 📂 移動 + ✏️ 重構 | 使用 @Observable |
| `HistoryView.swift` | `Views/History/HistoryView.swift` | 📂 移動 + ✏️ 重構 | 使用 @Query |
| `RecordDetailView.swift` | `Views/History/RecordDetailView.swift` | 📂 移動 | - |
| `SettingsView.swift` | `Views/Settings/SettingsView.swift` | 📂 移動 + ✏️ 擴充 | 使用 @Query |
| `EmailService.swift` | `Services/Email/EmailService.swift` | 📂 移動 + ⚠️ 標記廢棄 | 移除 MessageUI |
| `RunTracker.swift` | `Services/Tracking/RunTracker.swift` | 📂 移動 + ✏️ 重構 | 使用 @Observable |
| `LocationManager.swift` | `Services/Tracking/LocationManager.swift` | 📂 移動 + ✏️ 重構 | 使用 @Observable |
| `MotionManager.swift` | `Services/Tracking/MotionManager.swift` | 📂 移動 + ✏️ 重構 | 使用 @Observable |
| `FallDetection.swift` | `Services/Detection/FallDetection.swift` | 📂 移動 + ✏️ 重構 | 使用 @Observable |
| `RunRecord.swift` | `Models/Domain/RunRecord.swift` | 📂 移動 + ✏️ 重構 | Codable → @Model |
| `Settings.swift` | `Models/Settings/AppSettings.swift` | 📂 移動 + ✏️ 重構 | ObservableObject + UserDefaults → @Model |
| `RunRecordStore.swift` | ❌ 刪除 | 🗑️ 移除 | 由 @Query 取代 |

### SwiftData 模型定義範例

**RunRecord.swift（重構後）**
```swift
import Foundation
import SwiftData
import CoreLocation

@Model
final class RunRecord {
    var id: UUID
    var date: Date
    var duration: TimeInterval
    var stepCount: Int
    var averageCadence: Double
    var latitude: Double?
    var longitude: Double?
    
    // 關聯到跌倒事件（一對多）
    @Relationship(deleteRule: .cascade)
    var fallEvents: [FallEvent]?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval,
        stepCount: Int,
        averageCadence: Double,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.stepCount = stepCount
        self.averageCadence = averageCadence
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // Computed properties
    var location: CLLocation? {
        guard let latitude, let longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
}
```

**FallEvent.swift（新增）**
```swift
import Foundation
import SwiftData

@Model
final class FallEvent {
    var id: UUID
    var timestamp: Date
    var confidence: Double
    var maxImpact: Double
    var hadRotation: Bool
    var latitude: Double?
    var longitude: Double?
    var emailSent: Bool
    var emailSentAt: Date?
    
    // 關聯到跑步記錄（多對一）
    var runRecord: RunRecord?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        confidence: Double,
        maxImpact: Double,
        hadRotation: Bool,
        latitude: Double? = nil,
        longitude: Double? = nil,
        emailSent: Bool = false,
        emailSentAt: Date? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.confidence = confidence
        self.maxImpact = maxImpact
        self.hadRotation = hadRotation
        self.latitude = latitude
        self.longitude = longitude
        self.emailSent = emailSent
        self.emailSentAt = emailSentAt
    }
}
```

**AppSettings.swift（重構自 Settings.swift）**
```swift
import Foundation
import SwiftData

@Model
final class AppSettings {
    // 跌倒偵測設定
    var isFallDetectionEnabled: Bool
    var fallDetectionMode: String // "conservative", "balanced", "sensitive"
    
    // Email 設定
    var emergencyEmail: String
    var enableEmailNotifications: Bool
    var lastEmailSentDate: Date?
    
    // SendGrid 設定（敏感資料存 Keychain，這裡只存標記）
    var hasSendGridAPIKey: Bool
    var senderEmail: String
    var senderName: String
    
    // App 設定
    var isDarkModeEnabled: Bool?  // nil = 跟隨系統
    
    init(
        isFallDetectionEnabled: Bool = true,
        fallDetectionMode: String = "sensitive",
        emergencyEmail: String = "",
        enableEmailNotifications: Bool = true,
        hasSendGridAPIKey: Bool = false,
        senderEmail: String = "",
        senderName: String = ""
    ) {
        self.isFallDetectionEnabled = isFallDetectionEnabled
        self.fallDetectionMode = fallDetectionMode
        self.emergencyEmail = emergencyEmail
        self.enableEmailNotifications = enableEmailNotifications
        self.hasSendGridAPIKey = hasSendGridAPIKey
        self.senderEmail = senderEmail
        self.senderName = senderName
    }
    
    // 單例存取（使用 @Query 時不需要）
    static var shared: AppSettings?
}
```

**DetectionMode.swift（新增）**
```swift
import Foundation

enum DetectionMode: String, CaseIterable, Codable {
    case conservative = "conservative"
    case balanced = "balanced"
    case sensitive = "sensitive"
    
    var displayName: String {
        switch self {
        case .conservative: return "保守模式"
        case .balanced: return "平衡模式"
        case .sensitive: return "敏感模式"
        }
    }
    
    var description: String {
        switch self {
        case .conservative:
            return "減少誤報，適合日常高活動量使用者"
        case .balanced:
            return "平衡準確度與敏感度"
        case .sensitive:
            return "提高偵測率，適合測試與高風險使用者"
        }
    }
}
```

### 新增檔案清單

#### 優先級 P0（必要）
```
✅ App/FallDetectApp.swift（重構 - SwiftData 配置）
✅ Models/Domain/RunRecord.swift（重構 - @Model）
✅ Models/Settings/AppSettings.swift（重構 - @Model）
✅ Models/Settings/DetectionMode.swift（新增）
✅ Database/ModelContainer+Shared.swift（新增 - SwiftData 配置）
✅ Services/Email/SendGridService.swift（新增）
✅ Services/Email/EmailTemplate.swift（新增）
✅ Services/Network/NetworkManager.swift（新增 - URLSession）
✅ Services/Detection/DetectionThresholds.swift（新增）
✅ Utilities/Helpers/KeychainHelper.swift（新增 - 儲存 API Key）
✅ Design/Theme/ColorScheme.swift（新增）
```

#### 優先級 P1（重要）
```
🔵 Models/Domain/FallEvent.swift（新增 - @Model）
🔵 Database/PreviewContainer.swift（新增 - Preview 用）
🔵 Views/Components/Cards/GradientCard.swift（新增）
🔵 Views/Components/Progress/ProgressRing.swift（新增）
🔵 Views/Components/Buttons/PrimaryButton.swift（新增）
🔵 Views/Settings/APIConfigView.swift（新增）
🔵 Services/Audio/MetronomeService.swift（新增 - @Observable）
🔵 Services/Tracking/RunTracker.swift（重構 - @Observable）
🔵 Services/Tracking/LocationManager.swift（重構 - @Observable）
🔵 Services/Tracking/MotionManager.swift（重構 - @Observable）
🔵 Services/Detection/FallDetection.swift（重構 - @Observable）
🔵 Models/Network/SendGridRequest.swift（新增 - Codable）
🔵 Utilities/Extensions/Color+Extension.swift（新增）
🔵 Utilities/Extensions/Date+Extension.swift（新增）
```

#### 優先級 P2（可選）
```
⚪ Views/History/StatisticsView.swift（新增）
⚪ Views/Components/Charts/LineChartView.swift（新增）
⚪ Views/Settings/AboutView.swift（新增）
⚪ Design/Styles/ButtonStyles.swift（新增）
⚪ Resources/EmailTemplates/FallAlert.html（新增）
```

---

## 🔄 SwiftData 整合指南

### App 進入點配置

**FallDetectApp.swift（重構後）**
```swift
import SwiftUI
import SwiftData

@main
struct FallDetectApp: App {
    // SwiftData ModelContainer
    let modelContainer: ModelContainer
    
    init() {
        do {
            // 配置 Schema
            let schema = Schema([
                RunRecord.self,
                FallEvent.self,
                AppSettings.self
            ])
            
            // 配置 ModelConfiguration
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                // 可選：啟用 iCloud 同步
                // cloudKitDatabase: .automatic
            )
            
            // 建立 ModelContainer
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            // 初始化預設設定
            initializeDefaultSettings()
            
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                RunTrackingView()
                    .tabItem {
                        Label("跑步", systemImage: "figure.run")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("記錄", systemImage: "clock.arrow.circlepath")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("設定", systemImage: "gearshape")
                    }
            }
            .modelContainer(modelContainer)
        }
    }
    
    private func initializeDefaultSettings() {
        let context = modelContainer.mainContext
        
        // 檢查是否已有設定
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? context.fetch(descriptor).first {
            AppSettings.shared = settings
        } else {
            // 建立預設設定
            let defaultSettings = AppSettings()
            context.insert(defaultSettings)
            try? context.save()
            AppSettings.shared = defaultSettings
        }
    }
}
```

### View 中使用 SwiftData

**HistoryView.swift（使用 @Query）**
```swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 使用 @Query 自動查詢並監聽變化
    @Query(
        sort: \RunRecord.date,
        order: .reverse
    ) private var records: [RunRecord]
    
    @State private var selectedRecord: RunRecord?
    
    var body: some View {
        NavigationView {
            Group {
                if records.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "尚無跑步記錄",
                        subtitle: "開始您的第一次跑步吧！"
                    )
                } else {
                    List {
                        ForEach(records) { record in
                            RecordRow(record: record)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedRecord = record
                                }
                        }
                        .onDelete(perform: deleteRecords)
                    }
                }
            }
            .navigationTitle("歷史記錄")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !records.isEmpty {
                        EditButton()
                    }
                }
            }
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(record: record)
            }
        }
    }
    
    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
        try? modelContext.save()
    }
}
```

**RunSummaryView.swift（插入資料）**
```swift
import SwiftUI
import SwiftData
import CoreLocation

struct RunSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Bindable var tracker: RunTracker
    let location: CLLocation?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ... UI 內容 ...
                
                Button(action: saveRecord) {
                    Text("完成並保存")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
    
    private func saveRecord() {
        // 建立新記錄
        let record = RunRecord(
            duration: tracker.elapsedTime,
            stepCount: tracker.stepCount,
            averageCadence: averageCadence,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude
        )
        
        // 插入到資料庫
        modelContext.insert(record)
        
        // 儲存
        do {
            try modelContext.save()
            tracker.reset()
            dismiss()
        } catch {
            print("Failed to save record: \(error)")
        }
    }
}
```

**SettingsView.swift（讀取與更新設定）**
```swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 查詢設定（應該只有一筆）
    @Query private var settingsList: [AppSettings]
    
    private var settings: AppSettings? {
        settingsList.first
    }
    
    @State private var emailInput: String = ""
    @State private var selectedMode: DetectionMode = .sensitive
    
    var body: some View {
        NavigationView {
            Form {
                if let settings = settings {
                    Section(header: Text("跌倒偵測設定")) {
                        Toggle("啟用跌倒偵測", isOn: Binding(
                            get: { settings.isFallDetectionEnabled },
                            set: { newValue in
                                settings.isFallDetectionEnabled = newValue
                                try? modelContext.save()
                            }
                        ))
                        
                        Picker("偵測模式", selection: $selectedMode) {
                            ForEach(DetectionMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .onChange(of: selectedMode) { _, newValue in
                            settings.fallDetectionMode = newValue.rawValue
                            try? modelContext.save()
                        }
                    }
                    
                    Section(header: Text("緊急聯絡人")) {
                        TextField("Email", text: $emailInput)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: emailInput) { _, newValue in
                                settings.emergencyEmail = newValue
                                try? modelContext.save()
                            }
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear {
                if let settings = settings {
                    emailInput = settings.emergencyEmail
                    selectedMode = DetectionMode(rawValue: settings.fallDetectionMode) ?? .sensitive
                }
            }
        }
    }
}
```

### Observable 類別使用 @Observable

**RunTracker.swift（重構為 @Observable）**
```swift
import Foundation
import CoreMotion
import Observation

@Observable
final class RunTracker {
    var isRunning = false
    var elapsedTime: TimeInterval = 0
    var stepCount: Int = 0
    var cadence: Double = 0
    
    private var timer: Timer?
    private let pedometer = CMPedometer()
    private var startDate: Date?
    private var lastStepCount: Int = 0
    private var lastCadenceUpdate: Date = Date()
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        startDate = Date()
        elapsedTime = 0
        stepCount = 0
        cadence = 0
        
        // Timer 邏輯...
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startDate = self.startDate else { return }
            self.elapsedTime = Date().timeIntervalSince(startDate)
        }
        
        // Pedometer 邏輯...
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] data, error in
                guard let self = self, let data = data else { return }
                
                Task { @MainActor in
                    let currentSteps = data.numberOfSteps.intValue
                    self.stepCount = currentSteps
                    
                    let now = Date()
                    let timeInterval = now.timeIntervalSince(self.lastCadenceUpdate)
                    
                    if timeInterval >= 1.0 {
                        let stepsInInterval = currentSteps - self.lastStepCount
                        self.cadence = Double(stepsInInterval) / timeInterval * 60.0
                        self.lastStepCount = currentSteps
                        self.lastCadenceUpdate = now
                    }
                }
            }
        }
    }
    
    func stop() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        pedometer.stopUpdates()
    }
    
    func reset() {
        stop()
        elapsedTime = 0
        stepCount = 0
        cadence = 0
    }
}
```

### Preview 配置

**PreviewContainer.swift（新增）**
```swift
import SwiftData
import Foundation

@MainActor
class PreviewContainer {
    static let shared = PreviewContainer()
    
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            RunRecord.self,
            FallEvent.self,
            AppSettings.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            // 插入測試資料
            insertSampleData()
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
    
    private func insertSampleData() {
        let context = container.mainContext
        
        // 範例跑步記錄
        let record1 = RunRecord(
            duration: 1800,
            stepCount: 2500,
            averageCadence: 83,
            latitude: 25.0330,
            longitude: 121.5654
        )
        context.insert(record1)
        
        // 範例設定
        let settings = AppSettings(
            isFallDetectionEnabled: true,
            fallDetectionMode: "sensitive",
            emergencyEmail: "test@example.com"
        )
        context.insert(settings)
        
        try? context.save()
    }
}

// 在 Preview 中使用
#Preview {
    HistoryView()
        .modelContainer(PreviewContainer.shared.container)
}
```

---

## 🔧 技術實作細節

### SendGrid API 請求範例

```swift
// POST https://api.sendgrid.com/v3/mail/send
// Headers:
// - Authorization: Bearer YOUR_API_KEY
// - Content-Type: application/json

{
  "personalizations": [{
    "to": [{"email": "emergency@example.com"}],
    "subject": "🚨 跌倒偵測警告 - 緊急通知"
  }],
  "from": {
    "email": "noreply@falldetect.app",
    "name": "FallDetect 跌倒偵測系統"
  },
  "content": [{
    "type": "text/html",
    "value": "<html>...</html>"
  }]
}
```

### 漸層色彩實作

```swift
// 定義於 ColorScheme.swift
extension Color {
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [.blue, .purple]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        gradient: Gradient(colors: [.green, .mint]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let dangerGradient = LinearGradient(
        gradient: Gradient(colors: [.red, .orange]),
        startPoint: .leading,
        endPoint: .trailing
    )
}
```

### 圓形進度環元件

```swift
struct ProgressRing: View {
    let progress: Double // 0.0 ~ 1.0
    let lineWidth: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                ))
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
        }
    }
}
```

---

## ✅ 實作階段規劃

### Phase 1: 專案重構與資料夾結構調整 + SwiftData 遷移（預計 2-3 天）
**目標：建立清晰的模組化架構 + 完成 SwiftData 遷移**

#### 步驟 1.1: 建立新資料夾結構
```bash
# 在 Xcode 中建立以下資料夾群組
App/
Views/
  ├── Tracking/
  ├── History/
  ├── Settings/
  └── Components/
      ├── Cards/
      ├── Charts/
      ├── Progress/
      ├── Buttons/
      └── Common/
Services/
  ├── Email/
  ├── Tracking/
  ├── Detection/
  ├── Network/
  └── Audio/
Models/
  ├── Domain/
  ├── Settings/
  ├── Network/
  └── UI/
Database/              # 新增：SwiftData 配置
Utilities/
  ├── Constants/
  ├── Extensions/
  ├── Helpers/
  └── Validators/
Design/
  ├── Theme/
  └── Styles/
Resources/
  ├── EmailTemplates/
  ├── Localizations/
  └── Sounds/
```

#### 步驟 1.2: SwiftData 核心檔案建立（優先）
```swift
Day 1 上午：
✅ 建立 Models/Domain/RunRecord.swift（@Model 版本）
✅ 建立 Models/Settings/AppSettings.swift（@Model 版本）
✅ 建立 Models/Settings/DetectionMode.swift
✅ 建立 Database/ModelContainer+Shared.swift
✅ 建立 Database/PreviewContainer.swift

Day 1 下午：
✅ 重構 App/FallDetectApp.swift（配置 ModelContainer）
✅ 測試 SwiftData 基本功能（建立、讀取、更新、刪除）
✅ 確保 Preview 正常運作
```

#### 步驟 1.3: 遷移現有檔案並重構為 @Observable
```swift
Day 2：
✅ 重構 Services/Tracking/RunTracker.swift（@Observable）
✅ 重構 Services/Tracking/LocationManager.swift（@Observable）
✅ 重構 Services/Tracking/MotionManager.swift（@Observable）
✅ 重構 Services/Detection/FallDetection.swift（@Observable）

✅ 遷移 Views 到新位置
✅ 更新 View 使用 @Query 和 ModelContext
✅ 移除舊的 RunRecordStore.swift
```

#### 步驟 1.4: 建立基礎架構檔案
```swift
Day 3：
✅ 建立 Design/Theme/ColorScheme.swift
✅ 建立 Utilities/Constants/AppConstants.swift
✅ 建立 Utilities/Extensions/Color+Extension.swift
✅ 建立 Utilities/Extensions/Date+Extension.swift
✅ 建立 Utilities/Helpers/KeychainHelper.swift
✅ 確保專案編譯無誤
✅ 測試資料持久化（關閉 app 後資料仍存在）
```

---

### Phase 2: 跌倒偵測演算法優化（預計 1-2 天）
**目標：實作高靈敏度偵測模式**

#### 步驟 2.1: 重構 FallDetection.swift
```swift
1. 建立 Services/Detection/DetectionThresholds.swift
2. 建立 Models/Settings/DetectionMode.swift
3. 重構 FallDetection 類別：
   - 加入三級偵測模式
   - 實作累積信心度系統
   - 加入姿態變化偵測
   - 優化狀態機邏輯
4. 更新 Settings 加入模式選擇
```

#### 步驟 2.2: UI 整合
```swift
1. 修改 SettingsView 加入偵測模式選擇器
2. 加入即時信心度顯示
3. 加入測試按鈕
4. 加入偵測記錄查看
```

#### 步驟 2.3: 測試與調校
```
1. 進行輕度測試（掉落、坐下）
2. 進行中度測試（跑步、蹲下）
3. 調整閾值參數
4. 記錄誤報/漏報率
```

---

### Phase 3: UI/UX 美化（預計 2-3 天）
**目標：提升視覺質感與使用體驗**

#### 步驟 3.1: 建立設計系統
```swift
1. 實作 Design/Theme/ColorScheme.swift（漸層色彩）
2. 實作 Design/Theme/Typography.swift（字體系統）
3. 實作 Design/Theme/Spacing.swift（間距規範）
4. 實作 Design/Styles/ButtonStyles.swift（按鈕樣式）
```

#### 步驟 3.2: 建立共用 UI 元件（優先級 P1）
```swift
1. Views/Components/Cards/GradientCard.swift
2. Views/Components/Progress/ProgressRing.swift
3. Views/Components/Buttons/PrimaryButton.swift
4. Views/Components/Buttons/SecondaryButton.swift
5. Views/Components/Common/EmptyStateView.swift
```

#### 步驟 3.3: 重構主要頁面
```swift
Day 1: RunTrackingView
- 漸層背景
- 圓形進度環（步數/步頻）
- 卡片式布局
- 動畫效果

Day 2: HistoryView + RecordDetailView
- 卡片式列表
- 空狀態視圖
- 統計圖表（選配）

Day 3: SettingsView + MetronomeView
- 分組卡片設計
- 改良的表單元素
- 節拍器視覺化
```

#### 步驟 3.4: Dark Mode 適配
```swift
1. 檢查所有色彩支援 Dark Mode
2. 測試對比度
3. 調整陰影效果
```

---

### Phase 4: SendGrid API 整合（預計 2-3 天）
**目標：實現自動發送警告郵件**

#### 步驟 4.1: 建立網路層
```swift
1. Services/Network/NetworkManager.swift
2. Services/Network/APIClient.swift
3. Services/Network/NetworkError.swift
4. Models/Network/SendGridRequest.swift
5. Models/Network/SendGridResponse.swift
```

#### 步驟 4.2: 實作 SendGrid 服務
```swift
1. Services/Email/SendGridService.swift
   - sendFallAlertEmail() 方法
   - sendTestEmail() 方法
   - 錯誤處理
   - 重試機制

2. Services/Email/EmailTemplate.swift
   - HTML 範本生成
   - 動態內容注入
   - 樣式設計

3. Services/Email/EmailValidator.swift
   - Email 格式驗證
   - API Key 驗證
```

#### 步驟 4.3: Email 範本設計
```html
1. 建立 Resources/EmailTemplates/FallAlert.html
   - 響應式 HTML 設計
   - 警告橫幅
   - 位置地圖連結
   - 建議行動

2. 建立 Resources/EmailTemplates/TestEmail.html
   - 簡單的測試範本
```

#### 步驟 4.4: Settings 擴充
```swift
1. 擴充 Settings.swift
   - sendGridAPIKey (存入 Keychain)
   - senderEmail
   - senderName
   - enableEmailNotifications
   - lastEmailSentDate

2. 建立 Views/Settings/APIConfigView.swift
   - API Key 輸入（SecureField）
   - 發件人資訊設定
   - 測試郵件按鈕
   - 狀態顯示
```

#### 步驟 4.5: 整合到跌倒偵測流程
```swift
1. 修改 RunTrackingView.swift
   - 移除 MFMailComposeViewController
   - 整合 SendGridService
   - 自動發送邏輯
   - 錯誤提示

2. 加入發送頻率限制（5 分鐘冷卻）
3. 加入網路錯誤處理
4. 加入發送歷史記錄（選配）
```

#### 步驟 4.6: 測試
```
1. 註冊 SendGrid 免費帳號
2. 取得 API Key
3. 驗證發件人 Email
4. 測試發送功能
5. 測試錯誤情境（無網路、錯誤 API Key 等）
```

---

### Phase 5: 測試、優化與文件（預計 1-2 天）
**目標：確保品質與可維護性**

#### 步驟 5.1: 整合測試
```
1. 完整流程測試（跑步 → 跌倒 → 發送郵件）
2. 各種網路情境測試
3. 不同偵測模式測試
4. 記憶體與效能測試
```

#### 步驟 5.2: 優化
```swift
1. 程式碼重複消除
2. 效能瓶頸優化
3. 記憶體洩漏檢查
4. 電池消耗優化
```

#### 步驟 5.3: 文件撰寫
```markdown
1. 更新 README.md
2. 撰寫 API_SETUP.md（SendGrid 設定指南）
3. 撰寫 ARCHITECTURE.md（架構說明）
4. 更新程式碼註解
```

#### 步驟 5.4: Bug 修復與微調
```
1. 處理測試中發現的問題
2. UI/UX 細節調整
3. 使用者回饋收集與改進
```

---

## 📅 時間表總覽

| 階段 | 天數 | 主要產出 | 關鍵技術 | 檢查點 |
|-----|------|---------|---------|--------|
| Phase 1 | 2-3 天 | 📁 新資料夾結構 + SwiftData 遷移 | SwiftData @Model, @Observable | ✅ 專案可編譯 + 資料持久化 |
| Phase 2 | 1-2 天 | 🚨 優化的跌倒偵測演算法 | CoreMotion, @Observable | ✅ 偵測率達 90%+ |
| Phase 3 | 2-3 天 | 🎨 美化的 UI/UX | SwiftUI, @Query | ✅ 所有頁面完成重構 |
| Phase 4 | 2-3 天 | 📧 SendGrid 自動發信 | URLSession, Keychain | ✅ 郵件成功發送 |
| Phase 5 | 1-2 天 | 🧪 測試 + 📚 文件 | XCTest（選配） | ✅ 可發布版本 |
| **總計** | **8-13 天** | ✨ **FallDetect 2.0** | **Swift + SwiftData** | 🎉 |

---

## 🎯 每日檢查清單範例

### Day 1: SwiftData 核心建立
- [ ] 建立 Models/Domain/RunRecord.swift（@Model）
- [ ] 建立 Models/Settings/AppSettings.swift（@Model）
- [ ] 建立 Models/Settings/DetectionMode.swift
- [ ] 建立 Database/ModelContainer+Shared.swift
- [ ] 建立 Database/PreviewContainer.swift
- [ ] 重構 App/FallDetectApp.swift（配置 ModelContainer）
- [ ] 測試基本 CRUD 操作
- [ ] Git commit: "feat: Migrate to SwiftData"

### Day 2-3: 專案重構與 @Observable 遷移
- [ ] 建立所有資料夾結構
- [ ] 重構 RunTracker.swift（@Observable）
- [ ] 重構 LocationManager.swift（@Observable）
- [ ] 重構 MotionManager.swift（@Observable）
- [ ] 重構 FallDetection.swift（@Observable）
- [ ] 遷移 Views 到新位置並更新為使用 @Query
- [ ] 移除 RunRecordStore.swift
- [ ] 建立基礎 Extensions 和 Helpers
- [ ] 確保專案編譯成功
- [ ] Git commit: "refactor: Reorganize project structure + @Observable"

### Day 4-5: 跌倒偵測優化
- [ ] 實作 DetectionThresholds.swift
- [ ] 建立 Models/Domain/FallEvent.swift（@Model）
- [ ] 重構 FallDetection.swift（加入三級模式）
- [ ] 加入姿態變化偵測
- [ ] 修改 SettingsView（模式選擇，使用 @Query）
- [ ] 測試三種偵測模式
- [ ] Git commit: "feat: Enhanced fall detection algorithm"

### Day 6-8: UI/UX 美化
- [ ] 實作設計系統（色彩/字體/間距）
- [ ] 建立共用 UI 元件（使用 SwiftUI）
- [ ] 重構 RunTrackingView（使用 @Bindable）
- [ ] 重構 HistoryView（使用 @Query）
- [ ] 重構 SettingsView（使用 @Query）
- [ ] 重構 MetronomeView（使用 @Observable）
- [ ] Dark Mode 測試
- [ ] Git commit: "ui: Complete redesign with modern SwiftUI"

### Day 9-11: SendGrid 整合
- [ ] 實作 NetworkManager（URLSession）
- [ ] 實作 SendGridService（Codable + async/await）
- [ ] 實作 EmailTemplate
- [ ] 建立 HTML 範本
- [ ] 擴充 AppSettings（使用 @Model）
- [ ] 建立 APIConfigView
- [ ] 整合 Keychain（儲存 API Key）
- [ ] 整合到跌倒偵測流程
- [ ] 測試自動發信功能
- [ ] Git commit: "feat: SendGrid email integration"

### Day 12-13: 測試與優化
- [ ] 完整流程測試（建立、讀取、更新、刪除資料）
- [ ] SwiftData 效能測試（大量資料）
- [ ] 記憶體洩漏檢查（Instruments）
- [ ] Bug 修復
- [ ] 撰寫文件（README, ARCHITECTURE）
- [ ] 準備發布
- [ ] Git commit: "release: Version 2.0"

---

## 🚀 快速啟動指南

### 立即開始 Phase 1：

**Step 1: 建立 SwiftData 模型**
```swift
// 1. 在 Xcode 中建立 Models/Domain/RunRecord.swift
// 2. 複製上方的 @Model class RunRecord 程式碼
// 3. 建立 Models/Settings/AppSettings.swift
// 4. 建立 Models/Settings/DetectionMode.swift
```

**Step 2: 配置 ModelContainer**
```swift
// 1. 建立 Database/ModelContainer+Shared.swift
// 2. 修改 App/FallDetectApp.swift
// 3. 加入 ModelContainer 初始化
// 4. 測試編譯
```

**Step 3: 更新 Views**
```swift
// 1. 修改 HistoryView 使用 @Query
// 2. 修改 RunSummaryView 使用 ModelContext
// 3. 移除 RunRecordStore.swift
// 4. 測試資料儲存與讀取
```

**重要提醒：**
- ✅ 所有框架都使用 Apple 原生（import SwiftUI, SwiftData, CoreMotion 等）
- ✅ 不需要 CocoaPods 或 Swift Package Manager 第三方依賴
- ✅ 使用 @Observable 取代 ObservableObject（iOS 17+）
- ✅ 使用 @Query 取代手動資料查詢
- ✅ 使用 Keychain 儲存敏感資訊（API Key）
- ✅ 使用 URLSession 進行網路請求（不使用 Alamofire）

準備好開始了嗎？ 🚀

---

## 📝 注意事項

### SendGrid 限制
- 免費方案：每天 100 封郵件
- 需要驗證發件人 Email 地址
- API Key 需要安全儲存（建議使用 Keychain）

### 資料安全
- SendGrid API Key 應使用 Keychain 儲存，不使用 UserDefaults
- Email 發送記錄應加密儲存
- 敏感資訊不應包含在 Git 版本控制中

### 向下相容
- 保留現有資料格式
- 確保舊版記錄可正常讀取
- 提供設定遷移機制

### 效能考量
- Email 發送應在背景執行緒
- 避免阻塞主執行緒
- 實作發送佇列機制（多次跌倒偵測時）
- 網路錯誤時的重試機制

---

## 🎨 設計參考

### 色彩方案
- 主色：#4A90E2 (藍色)
- 輔助色：#9B59B6 (紫色)
- 成功：#2ECC71 (綠色)
- 警告：#F39C12 (橙色)
- 危險：#E74C3C (紅色)

### 字體
- 標題：SF Pro Display Bold
- 正文：SF Pro Text Regular
- 數字：SF Pro Rounded

---

## 📚 相關文件

1. SendGrid API 文件：https://docs.sendgrid.com/api-reference/mail-send/mail-send
2. SwiftUI 動畫指南：https://developer.apple.com/documentation/swiftui/animations
3. iOS 設計規範：https://developer.apple.com/design/human-interface-guidelines/

---

**版本**: 1.0  
**建立日期**: 2025年12月16日  
**作者**: GitHub Copilot  
**狀態**: 待審核

