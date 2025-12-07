# FallDetect 實作計劃

## 階段一：基本跑步追蹤

### 任務
- 建立跑步追蹤主畫面 UI
- 實作開始/停止按鈕
- 使用 Timer 計算跑步時間
- 使用 CMPedometer 取得步數
- 計算並顯示每分鐘步頻
- 跑步結束後顯示總結畫面

### 檔案
- `RunTrackingView.swift` - 主追蹤畫面
- `RunSummaryView.swift` - 總結畫面
- `RunTracker.swift` - 追蹤邏輯管理

### 權限設定
- Info.plist 加入 `NSMotionUsageDescription`

---

## 階段二：GPS 定位

### 任務
- 整合 CoreLocation
- 取得並顯示當前位置
- 記錄跑步路線座標點（可選）

### 檔案
- `LocationManager.swift` - 位置管理
- 更新 `RunTrackingView.swift` 顯示位置

### 權限設定
- Info.plist 加入 `NSLocationWhenInUseUsageDescription`

---

## 階段三：感測器數據

### 任務
- 使用 CMMotionManager 取得陀螺儀數據
- 取得加速度計數據
- 顯示 xyz 軸方向和加速度
- 即時更新感測器讀數

### 檔案
- `MotionManager.swift` - 感測器管理
- `SensorDataView.swift` - 感測器數據顯示（可選獨立畫面或整合到主畫面）

---

## 階段四：記錄功能

### 任務
- 設計數據模型（RunRecord）
- 實作數據儲存（使用 UserDefaults 或 CoreData）
- 建立歷史記錄列表畫面
- 建立記錄詳情畫面
- 實作刪除記錄功能

### 檔案
- `RunRecord.swift` - 數據模型
- `RunRecordStore.swift` - 數據儲存管理
- `HistoryView.swift` - 歷史記錄列表
- `RecordDetailView.swift` - 記錄詳情

---

## 階段五：跌倒偵測

### 任務
- 設計跌倒偵測演算法
- 分析加速度突變和姿態變化
- 設定閾值避免誤判
- 整合到跑步追蹤流程

### 檔案
- `FallDetection.swift` - 跌倒偵測邏輯
- 更新 `RunTracker.swift` 整合偵測

---

## 階段六：Email 通知

### 任務
- 建立設定畫面
- 實作跌倒偵測開關
- 實作緊急聯絡人 email 設定
- 使用 MessageUI 發送 email
- 跌倒時觸發 email 通知

### 檔案
- `SettingsView.swift` - 設定畫面
- `EmailService.swift` - Email 發送服務
- 更新 `FallDetection.swift` 觸發通知

---

## 導航結構

- 主畫面：跑步追蹤
- Tab 或 Navigation：歷史記錄、設定

## 技術要點

- 使用 @StateObject 和 ObservableObject 管理狀態
- 背景執行時保持感測器運作
- 注意電池消耗優化
- 錯誤處理和權限檢查

