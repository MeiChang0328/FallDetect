//
//  SettingsView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var emailInput: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("跌倒偵測設定")) {
                    Toggle("啟用跌倒偵測", isOn: $settings.isFallDetectionEnabled)
                    
                    Text("當偵測到跌倒時，系統會自動發送 email 通知給緊急聯絡人。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("緊急聯絡人")) {
                    TextField("緊急聯絡人 Email", text: $emailInput)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onAppear {
                            emailInput = settings.emergencyEmail
                        }
                        .onChange(of: emailInput) { newValue in
                            settings.emergencyEmail = newValue
                        }
                    
                    Text("請輸入緊急聯絡人的 email 地址。當偵測到跌倒時，系統會發送通知到此地址。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("關於")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
}

