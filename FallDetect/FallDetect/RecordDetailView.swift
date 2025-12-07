//
//  RecordDetailView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import SwiftUI
import CoreLocation

struct RecordDetailView: View {
    let record: RunRecord
    @ObservedObject var recordStore: RunRecordStore
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    SummaryRow(title: "日期時間", value: record.formattedDate)
                    SummaryRow(title: "跑步時間", value: record.formattedDuration)
                    SummaryRow(title: "總步數", value: "\(record.stepCount) 步")
                    SummaryRow(title: "平均步頻", value: "\(Int(record.averageCadence)) 步/分鐘")
                    
                    if let location = record.location {
                        SummaryRow(title: "位置", value: formatLocation(location))
                    }
                }
                .padding()
                
                Spacer()
                
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Text("刪除記錄")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("記錄詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
            .alert("刪除記錄", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    recordStore.deleteRecord(record)
                    dismiss()
                }
            } message: {
                Text("確定要刪除此記錄嗎？此操作無法復原。")
            }
        }
    }
    
    private func formatLocation(_ location: CLLocation) -> String {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        return String(format: "%.6f, %.6f", latitude, longitude)
    }
}

#Preview {
    RecordDetailView(
        record: RunRecord(
            duration: 1800,
            stepCount: 2500,
            averageCadence: 83,
            location: nil
        ),
        recordStore: RunRecordStore()
    )
}

