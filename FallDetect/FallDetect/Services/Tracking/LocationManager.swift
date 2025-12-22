//
//  LocationManager.swift
//  FallDetect
//
//  Created by 張郁眉 on 2025/12/7.
//  Refactored to use @Observable on 2025/12/16
//

import Foundation
import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject {
    private let locationManager = CLLocationManager()
    
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationString: String = "取得位置中..."
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 每10公尺更新一次
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    private func updateLocationString() {
        guard let location = location else {
            locationString = "無法取得位置"
            return
        }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        locationString = String(format: "緯度: %.6f\n經度: %.6f", latitude, longitude)
    }
    
    deinit {
        stopLocationUpdates()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // @Observable 會自動追蹤屬性變更
        self.location = location
        updateLocationString()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationString = "位置取得失敗"
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            locationString = "位置權限被拒絕"
        case .notDetermined:
            requestPermission()
        @unknown default:
            break
        }
    }
}
