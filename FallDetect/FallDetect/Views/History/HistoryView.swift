//
//  HistoryView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use SwiftData on 2025/12/16
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RunRecord.date, order: .reverse) private var records: [RunRecord]
    @State private var selectedRecord: RunRecord?
    
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
                
                Group {
                    if records.isEmpty {
                        emptyStateView
                    } else {
                        recordsList
                    }
                }
            }
            .navigationTitle("歷史記錄")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !records.isEmpty {
                        EditButton()
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(record: record)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 圖示
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.1), Color.appSecondary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appPrimary, .appSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("尚無跑步記錄")
                    .font(.appTitle3)
                    .foregroundColor(.appTextPrimary)
                
                Text("開始您的第一次跑步吧！")
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Records List
    
    private var recordsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(records) { record in
                    RecordRow(record: record)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRecord = record
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .padding()
            .padding(.top, 8)
        }
    }
    
    // MARK: - Actions
    
    private func deleteRecords(at offsets: IndexSet) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            for index in offsets {
                modelContext.delete(records[index])
            }
            
            do {
                try modelContext.save()
            } catch {
                print("❌ 刪除記錄失敗: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Record Row

struct RecordRow: View {
    let record: RunRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 頂部：日期與箭頭
            HStack {
                Text(record.formattedDate)
                    .font(.appTitle3)
                    .foregroundColor(.appTextPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            }
            
            // 統計數據網格
            HStack(spacing: 16) {
                // 時間
                StatInfoItem(
                    icon: "clock.fill",
                    value: record.formattedDuration,
                    color: .appPrimary
                )
                
                Divider()
                    .frame(height: 30)
                
                // 步數
                StatInfoItem(
                    icon: "figure.walk",
                    value: "\(record.stepCount)",
                    label: "步",
                    color: .appSuccess
                )
                
                Divider()
                    .frame(height: 30)
                
                // 步頻
                StatInfoItem(
                    icon: "gauge",
                    value: "\(Int(record.averageCadence))",
                    label: "步/分",
                    color: .appSecondary
                )
            }
            
            // 跌倒事件警告（如果有）
            if let fallEvents = record.fallEvents, !fallEvents.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.appCaption)
                        .foregroundColor(.appDanger)
                    
                    Text("\(fallEvents.count) 次跌倒偵測")
                        .font(.appCaption)
                        .foregroundColor(.appDanger)
                    
                    Spacer()
                }
                .padding(8)
                .background(Color.appDanger.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.appShadowLight, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Stat Info Item

struct StatInfoItem: View {
    let icon: String
    let value: String
    var label: String = ""
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.appCaption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.appNumberSmall)
                    .foregroundColor(.appTextPrimary)
                
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("With Records") {
    HistoryView()
        .modelContainer(ModelContainer.preview)
}

#Preview("Empty State") {
    HistoryView()
        .modelContainer(ModelContainer.emptyPreview)
}
