//
//  RunRecordStore.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import Foundation
import Combine

class RunRecordStore: ObservableObject {
    @Published var records: [RunRecord] = []
    
    private let recordsKey = "RunRecords"
    
    init() {
        loadRecords()
    }
    
    // 載入記錄
    func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: recordsKey),
              let decoded = try? JSONDecoder().decode([RunRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded.sorted { $0.date > $1.date } // 最新的在前
    }
    
    // 保存記錄
    func saveRecords() {
        guard let encoded = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(encoded, forKey: recordsKey)
    }
    
    // 新增記錄
    func addRecord(_ record: RunRecord) {
        records.insert(record, at: 0) // 插入到最前面
        saveRecords()
    }
    
    // 刪除記錄
    func deleteRecord(_ record: RunRecord) {
        records.removeAll { $0.id == record.id }
        saveRecords()
    }
    
    // 刪除所有記錄
    func deleteAllRecords() {
        records.removeAll()
        saveRecords()
    }
}

