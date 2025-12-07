# FallDetect 任務清單

## 階段一：基本跑步追蹤

- [x] 建立跑步追蹤主畫面 UI（RunTrackingView.swift）
- [x] 實作開始/停止按鈕功能
- [x] 使用 Timer 計算並顯示跑步時間
- [x] 使用 CMPedometer 取得並顯示步數
- [x] 計算並動態更新每分鐘步頻
- [x] 建立跑步總結畫面（RunSummaryView.swift）
- [x] 建立追蹤邏輯管理（RunTracker.swift）
- [x] 在 Info.plist 加入 NSMotionUsageDescription 權限

---

## 階段二：GPS 定位

- [x] 建立位置管理（LocationManager.swift）
- [x] 在主畫面顯示當前位置
- [x] 在 Info.plist 加入 NSLocationWhenInUseUsageDescription 權限

---

## 階段三：感測器數據

- [x] 建立感測器管理（MotionManager.swift）
- [x] 顯示陀螺儀和加速度計 xyz 軸數據

---

## 階段四：記錄功能

- [x] 設計並建立數據模型（RunRecord.swift）
- [x] 實作數據儲存管理（RunRecordStore.swift）
- [x] 建立歷史記錄列表畫面（HistoryView.swift）
- [x] 建立記錄詳情畫面（RecordDetailView.swift）
- [x] 實作刪除記錄功能

---

## 階段五：跌倒偵測

- [x] 設計跌倒偵測演算法（FallDetection.swift）
- [x] 整合跌倒偵測到跑步追蹤流程

---

## 階段六：Email 通知

- [x] 建立設定畫面（SettingsView.swift）
- [x] 實作 Email 發送服務（EmailService.swift）
- [x] 跌倒時觸發 email 通知功能

---

## 其他

- [x] 建立導航結構（Tab 或 Navigation）整合所有畫面

