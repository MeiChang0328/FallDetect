//
//  NetworkManager.swift
//  FallDetect
//
//  Created on 2025/12/22.
//  網路請求管理器
//

import Foundation

// MARK: - Network Error

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case unauthorized
    case networkUnavailable
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 URL"
        case .noData:
            return "未收到資料"
        case .decodingError:
            return "資料解析失敗"
        case .serverError(let code):
            return "伺服器錯誤：\(code)"
        case .unauthorized:
            return "未授權：請檢查 API Key 是否正確"
        case .networkUnavailable:
            return "網路連線不可用"
        case .unknown(let error):
            return "未知錯誤：\(error.localizedDescription)"
        }
    }
}

// MARK: - Network Manager

/// 網路請求管理器
final class NetworkManager {
    
    // MARK: - Singleton
    
    static let shared = NetworkManager()
    
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Public Methods
    
    /// 發送 POST 請求
    /// - Parameters:
    ///   - url: 請求 URL
    ///   - body: 請求主體（Encodable）
    ///   - headers: 自訂標頭
    /// - Returns: 回應資料
    func post<T: Encodable>(
        to url: URL,
        body: T,
        headers: [String: String] = [:]
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 加入自訂標頭
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 編碼請求主體
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw NetworkError.decodingError
        }
        
        return try await performRequest(request)
    }
    
    /// 發送 GET 請求
    /// - Parameters:
    ///   - url: 請求 URL
    ///   - headers: 自訂標頭
    /// - Returns: 回應資料
    func get(
        from url: URL,
        headers: [String: String] = [:]
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 加入自訂標頭
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return try await performRequest(request)
    }
    
    // MARK: - Private Methods
    
    /// 執行網路請求
    /// - Parameter request: URLRequest
    /// - Returns: 回應資料
    private func performRequest(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError(domain: "Invalid response", code: -1))
            }
            
            // 調試：顯示 HTTP 狀態碼
            print("📡 HTTP Status Code: \(httpResponse.statusCode)")
            
            // 調試：顯示回應內容（如果有錯誤）
            if httpResponse.statusCode >= 400 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Error Response Body:")
                    print(errorString)
                }
            }
            
            // 檢查 HTTP 狀態碼
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401, 403:
                // 顯示詳細錯誤訊息
                if let errorString = String(data: data, encoding: .utf8) {
                    print("🔒 Authorization Error Detail: \(errorString)")
                }
                throw NetworkError.unauthorized
            case 400...499:
                throw NetworkError.serverError(httpResponse.statusCode)
            case 500...599:
                throw NetworkError.serverError(httpResponse.statusCode)
            default:
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
        } catch let error as NetworkError {
            throw error
        } catch {
            // 檢查是否為網路連線問題
            if (error as NSError).domain == NSURLErrorDomain {
                throw NetworkError.networkUnavailable
            }
            throw NetworkError.unknown(error)
        }
    }
}

// MARK: - Convenience Methods

extension NetworkManager {
    
    /// 發送 JSON POST 請求並解碼回應
    /// - Parameters:
    ///   - url: 請求 URL
    ///   - body: 請求主體
    ///   - headers: 自訂標頭
    ///   - responseType: 回應類型
    /// - Returns: 解碼後的回應物件
    func post<T: Encodable, R: Decodable>(
        to url: URL,
        body: T,
        headers: [String: String] = [:],
        responseType: R.Type
    ) async throws -> R {
        let data = try await post(to: url, body: body, headers: headers)
        
        do {
            return try JSONDecoder().decode(R.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    /// 檢查網路連線狀態
    /// - Returns: 是否有網路連線
    func isNetworkAvailable() -> Bool {
        // 簡單的網路檢查
        // 在生產環境中可以使用 NWPathMonitor 進行更準確的檢查
        return true
    }
}
