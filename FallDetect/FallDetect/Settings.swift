//
//  Settings.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//

import Foundation
import Combine

class Settings: ObservableObject {
    @Published var isFallDetectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isFallDetectionEnabled, forKey: "isFallDetectionEnabled")
        }
    }
    
    @Published var emergencyEmail: String {
        didSet {
            UserDefaults.standard.set(emergencyEmail, forKey: "emergencyEmail")
        }
    }
    
    static let shared = Settings()
    
    private init() {
        self.isFallDetectionEnabled = UserDefaults.standard.bool(forKey: "isFallDetectionEnabled")
        self.emergencyEmail = UserDefaults.standard.string(forKey: "emergencyEmail") ?? ""
    }
}

