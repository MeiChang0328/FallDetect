//
//  RecordDetailView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use SwiftData on 2025/12/16
//

import SwiftUI
import SwiftData
import MapKit

struct RecordDetailView: View {
    let record: RunRecord
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var selectedFallEvent: FallEvent?
    
    var body: some View {
        NavigationView {
            ZStack {
                // 漸變背景
                LinearGradient(
                    colors: [Color.appBackground, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 基本資訊
                        basicInfoSection
                        
                        // 跌倒事件（如果有）
                        if let fallEvents = record.fallEvents, !fallEvents.isEmpty {
                            fallEventsSection(fallEvents)
                        }
                        
                        // 地圖位置（如果有）
                        if record.latitude != nil, record.longitude != nil {
                            mapSection
                        }
                        
                        Spacer()
                        
                        // 刪除按鈕
                        deleteButton
                    }
                    .padding()
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("記錄詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
            .alert("刪除記錄", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    deleteRecord()
                }
            } message: {
                Text("確定要刪除此記錄嗎？此操作無法復原。")
            }
            .sheet(item: $selectedFallEvent) { event in
                FallEventDetailView(event: event)
            }
        }
    }
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.appBody)
                    .foregroundColor(.appPrimary)
                Text("跑步統計")
                    .font(.appTitle3)
                    .foregroundColor(.appTextPrimary)
            }
            
            // 統計數據網格
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatCard(
                        icon: "calendar",
                        title: "日期",
                        value: record.formattedDate,
                        color: .appPrimary,
                        style: .compact
                    )
                }
                
                HStack(spacing: 12) {
                    StatCard(
                        icon: "clock.fill",
                        title: "時間",
                        value: record.formattedDuration,
                        color: .appPrimary,
                        style: .expanded
                    )
                    
                    StatCard(
                        icon: "figure.walk",
                        title: "步數",
                        value: "\(record.stepCount)",
                        unit: "步",
                        color: .appSuccess,
                        style: .expanded
                    )
                }
                
                StatCard(
                    icon: "gauge",
                    title: "平均步頻",
                    value: "\(Int(record.averageCadence))",
                    unit: "步/分鐘",
                    color: .appSecondary,
                    style: .expanded
                )
                
                if record.estimatedDistance > 0 {
                    StatCard(
                        icon: "map",
                        title: "預估距離",
                        value: String(format: "%.2f", record.estimatedDistance),
                        unit: "公里",
                        color: .appWarning,
                        style: .expanded
                    )
                }
                
                if let lat = record.latitude, let lon = record.longitude {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.appCaption)
                                .foregroundColor(.appPrimary)
                            Text("座標位置")
                                .font(.appBodySecondary)
                                .foregroundColor(.appTextSecondary)
                        }
                        Text(String(format: "%.6f, %.6f", lat, lon))
                            .font(.appCaption)
                            .foregroundColor(.appTextPrimary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.appPrimary.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.appShadowLight, radius: 4, x: 0, y: 2)
    }
    
    private func fallEventsSection(_ events: [FallEvent]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.appBody)
                    .foregroundColor(.appDanger)
                Text("跌倒事件 (\(events.count))")
                    .font(.appTitle3)
                    .foregroundColor(.appDanger)
            }
            
            // 事件列表
            VStack(spacing: 10) {
                ForEach(events.sorted(by: { $0.timestamp < $1.timestamp })) { event in
                    FallEventCard(event: event)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFallEvent = event
                        }
                }
            }
        }
        .padding()
        .background(Color.appDanger.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appDanger.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "map.fill")
                    .font(.appBody)
                    .foregroundColor(.appPrimary)
                Text("位置地圖")
                    .font(.appTitle3)
                    .foregroundColor(.appTextPrimary)
            }
            
            if let lat = record.latitude, let lon = record.longitude {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                
                // 地圖
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))) {
                    Marker("跑步位置", coordinate: coordinate)
                }
                .frame(height: 200)
                .cornerRadius(12)
                
                // Google Maps 連結
                Link(destination: record.googleMapsURL) {
                    HStack {
                        Image(systemName: "map.fill")
                            .font(.appBody)
                        Text("在 Google Maps 中開啟")
                            .font(.appBody)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        LinearGradient(
                            colors: [.appPrimary, .appSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.appShadowLight, radius: 4, x: 0, y: 2)
    }
    
    private var deleteButton: some View {
        Button(action: {
            showDeleteAlert = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "trash.fill")
                    .font(.appBody)
                Text("刪除記錄")
                    .font(.appTitle3)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appDanger)
            .cornerRadius(12)
            .shadow(color: Color.appDanger.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Actions
    
    private func deleteRecord() {
        modelContext.delete(record)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("❌ 刪除記錄失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - Fall Event Card

struct FallEventCard: View {
    let event: FallEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 標題列
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                    Text(event.timestamp, style: .time)
                        .font(.appBodySecondary)
                        .foregroundColor(.appTextPrimary)
                }
                
                Spacer()
                
                if event.emailSent {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.appSuccess)
                        Text("已發送Email")
                            .font(.system(size: 10))
                            .foregroundColor(.appSuccess)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appSuccess.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
            // 數據指標
            HStack(spacing: 14) {
                // 信心度
                HStack(spacing: 5) {
                    Image(systemName: "gauge.medium")
                        .font(.system(size: 12))
                        .foregroundColor(.appPrimary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(Int(event.confidence * 100))%")
                            .font(.appNumberSmall)
                            .foregroundColor(.appTextPrimary)
                        Text("信心度")
                            .font(.system(size: 9))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                Divider()
                    .frame(height: 28)
                
                // 衝擊力
                HStack(spacing: 5) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 12))
                        .foregroundColor(.appWarning)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(format: "%.1fG", event.maxImpact))
                            .font(.appNumberSmall)
                            .foregroundColor(.appTextPrimary)
                        Text("衝擊力")
                            .font(.system(size: 9))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                if event.hadRotation {
                    Divider()
                        .frame(height: 28)
                    
                    // 旋轉標記
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(.appSecondary)
                        Text("旋轉")
                            .font(.appCaption)
                            .foregroundColor(.appTextPrimary)
                    }
                }
            }
            
            // 位置資訊標記
            if event.latitude != nil, event.longitude != nil {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.appPrimary)
                    Text("有位置資訊")
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.appCardBackground)
        .cornerRadius(10)
        .shadow(color: Color.appShadowLight, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Fall Event Detail View

struct FallEventDetailView: View {
    let event: FallEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 基本資訊
                    VStack(spacing: 12) {
                        DetailRow(title: "時間", value: event.timestamp.formatted(date: .abbreviated, time: .standard))
                        DetailRow(title: "信心度", value: "\(Int(event.confidence * 100))%")
                        DetailRow(title: "最大衝擊力", value: String(format: "%.2f G", event.maxImpact))
                        DetailRow(title: "姿態變化", value: String(format: "%.1f°", event.maxAttitudeChange * 180 / .pi))
                        DetailRow(title: "有旋轉", value: event.hadRotation ? "是" : "否")
                    }
                    .padding()
                    
                    // Email 狀態
                    VStack(spacing: 12) {
                        HStack {
                            Text("Email 通知")
                                .font(.headline)
                            Spacer()
                        }
                        
                        if event.emailSent, let sentAt = event.emailSentAt {
                            DetailRow(title: "發送狀態", value: "✅ 已發送")
                            DetailRow(title: "發送時間", value: sentAt.formatted(date: .abbreviated, time: .standard))
                        } else {
                            DetailRow(title: "發送狀態", value: "❌ 未發送")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 位置資訊
                    if let lat = event.latitude, let lon = event.longitude {
                        VStack(spacing: 12) {
                            HStack {
                                Text("位置資訊")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            
                            Map(initialPosition: .region(MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            ))) {
                                Marker("跌倒位置", coordinate: coordinate)
                                    .tint(.red)
                            }
                            .frame(height: 200)
                            .cornerRadius(8)
                            
                            DetailRow(title: "經緯度", value: String(format: "%.6f, %.6f", lat, lon))
                            
                            if let mapsURL = event.googleMapsURL {
                                Link(destination: mapsURL) {
                                    HStack {
                                        Image(systemName: "map.fill")
                                        Text("在 Google Maps 中開啟")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("跌倒事件詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Previews

#Preview("Normal Record") {
    let record = RunRecord(
        date: Date(),
        duration: 1800,
        stepCount: 2500,
        averageCadence: 83,
        latitude: 25.0330,
        longitude: 121.5654
    )
    RecordDetailView(record: record)
        .modelContainer(ModelContainer.preview)
}

#Preview("Record with Falls") {
    let context = PreviewContainer.shared.container.mainContext
    let records = try! context.fetch(FetchDescriptor<RunRecord>())
    
    if let record = records.first {
        RecordDetailView(record: record)
            .modelContainer(ModelContainer.preview)
    } else {
        Text("No preview data available")
    }
}
