//
//  MetronomeView.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import SwiftUI
import AVFoundation
import AudioToolbox
import Combine

struct MetronomeView: View {
    @ObservedObject var metronome: Metronome
    @Environment(\.dismiss) var dismiss
    @State private var decreaseTimer: Timer?
    @State private var increaseTimer: Timer?
    @State private var isDecreasePressed = false
    @State private var isIncreasePressed = false
    
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
                        // 減少按鈕（支援長按）
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                            .onLongPressGesture(minimumDuration: 0.3, pressing: { isPressing in
                                if isPressing {
                                    // 按下開始
                                    isDecreasePressed = true
                                    // 立即開始連續減少
                                    startDecreasing()
                                } else {
                                    // 放開
                                    stopDecreasing()
                                    // 延遲重置，避免觸發點擊
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isDecreasePressed = false
                                    }
                                }
                            }, perform: {
                                // 長按完成（這裡留空）
                            })
                            .onTapGesture {
                                // 短按：直接減少（只有在非長按狀態時）
                                if !isDecreasePressed {
                                    metronome.decreaseBPM()
                                }
                            }
                        
                        // 中間顯示數字
                        Text("\(metronome.bpm)")
                            .font(.system(size: 80, weight: .bold))
                            .frame(minWidth: 150)
                        
                        // 增加按鈕（支援長按）
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                            .onLongPressGesture(minimumDuration: 0.3, pressing: { isPressing in
                                if isPressing {
                                    // 按下開始
                                    isIncreasePressed = true
                                    // 立即開始連續增加
                                    startIncreasing()
                                } else {
                                    // 放開
                                    stopIncreasing()
                                    // 延遲重置，避免觸發點擊
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isIncreasePressed = false
                                    }
                                }
                            }, perform: {
                                // 長按完成（這裡留空）
                            })
                            .onTapGesture {
                                // 短按：直接增加（只有在非長按狀態時）
                                if !isIncreasePressed {
                                    metronome.increaseBPM()
                                }
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
    
    // 開始快速減少
    private func startDecreasing() {
        decreaseTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            metronome.decreaseBPM()
        }
    }
    
    // 停止快速減少
    private func stopDecreasing() {
        decreaseTimer?.invalidate()
        decreaseTimer = nil
    }
    
    // 開始快速增加
    private func startIncreasing() {
        increaseTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            metronome.increaseBPM()
        }
    }
    
    // 停止快速增加
    private func stopIncreasing() {
        increaseTimer?.invalidate()
        increaseTimer = nil
    }
}

// 節拍器邏輯類別
class Metronome: ObservableObject {
    @Published var bpm: Int = 120 {
        didSet {
            if isPlaying {
                stop()
                start()
            }
        }
    }
    @Published var isPlaying: Bool = false
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        // 創建一個簡短的音效檔案 URL（使用系統音效）
        // 如果有自定義音檔，可以用 Bundle.main.url
        
        // 配置音訊 session 為播放模式
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }
    
    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        
        let interval = 60.0 / Double(bpm)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playTick()
        }
        // 立即播放第一次
        playTick()
    }
    
    func stop() {
        guard isPlaying else { return }
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    func increaseBPM() {
        if bpm < 240 {
            bpm += 1
        }
    }
    
    func decreaseBPM() {
        if bpm > 40 {
            bpm -= 1
        }
    }
    
    private func playTick() {
        // 使用清脆響亮的系統音效
        // 1057 - 鍵盤點擊音效（清脆）
        AudioServicesPlaySystemSound(1057)
        
        // 使用強觸覺反饋
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred(intensity: 1.0)
    }
    
    deinit {
        stop()
    }
}

#Preview {
    MetronomeView(metronome: Metronome())
}
