//
//  HistoryView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var recordStore: RunRecordStore
    @State private var selectedRecord: RunRecord?
    
    var body: some View {
        NavigationView {
            Group {
                if recordStore.records.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("尚無跑步記錄")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("開始您的第一次跑步吧！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(recordStore.records) { record in
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
                    if !recordStore.records.isEmpty {
                        EditButton()
                    }
                }
            }
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(record: record, recordStore: recordStore)
            }
        }
    }
    
    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            recordStore.deleteRecord(recordStore.records[index])
        }
    }
}

struct RecordRow: View {
    let record: RunRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.formattedDate)
                    .font(.headline)
                
                HStack(spacing: 15) {
                    Label("\(record.formattedDuration)", systemImage: "clock")
                    Label("\(record.stepCount) 步", systemImage: "figure.walk")
                    Label("\(Int(record.averageCadence)) 步/分", systemImage: "gauge")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView(recordStore: RunRecordStore())
}

