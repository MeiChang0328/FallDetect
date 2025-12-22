//
//  MetronomeView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use @Observable on 2025/12/16
//

import SwiftUI

struct MetronomeView: View {
    let metronome: Metronome
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // 顯示當前 BPM
                VStack(spacing: 10) {
                    Text("節拍器")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 30) {
                        // 減少按鈕
                        Button(action: {
                            metronome.decreaseBPM()
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }
                        
                        // 中間顯示數字
                        Text("\(metronome.bpm)")
                            .font(.system(size: 80, weight: .bold))
                            .frame(minWidth: 150)
                        
                        // 增加按鈕
                        Button(action: {
                            metronome.increaseBPM()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("BPM (每分鐘節拍數)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 開始/停止按鈕
                Button(action: {
                    if metronome.isPlaying {
                        metronome.stop()
                    } else {
                        metronome.start()
                    }
                }) {
                    HStack {
                        Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                        Text(metronome.isPlaying ? "停止" : "開始")
                    }
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(metronome.isPlaying ? Color.red : Color.green)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("節拍器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    MetronomeView(metronome: Metronome())
}
