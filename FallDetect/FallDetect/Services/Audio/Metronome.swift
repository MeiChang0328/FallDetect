//
//  Metronome.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use @Observable on 2025/12/16
//

import Foundation
import AVFoundation
import AudioToolbox
import UIKit
import Observation

@Observable
final class Metronome {
    var bpm: Int = 120 {
        didSet {
            if isPlaying {
                stop()
                start()
            }
        }
    }
    var isPlaying: Bool = false
    
    private var timer: Timer?
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
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
    
    func setBPM(_ newBPM: Int) {
        let clampedBPM = max(40, min(240, newBPM))
        if bpm != clampedBPM {
            bpm = clampedBPM
        }
    }
    
    private func playTick() {
        // 使用清脆響亮的系統音效 1057 - 鍵盤點擊音效
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
