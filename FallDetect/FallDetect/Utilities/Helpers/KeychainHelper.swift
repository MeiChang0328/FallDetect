//
//  KeychainHelper.swift
//  FallDetect
//
//  Created on 2025/12/22.
//  用於安全儲存敏感資料（如 SendGrid API Key）
//

import Foundation
import Security

/// Keychain 操作輔助類別
/// 用於安全儲存和讀取敏感資訊（如 API Keys）
final class KeychainHelper {
    
    // MARK: - Singleton
    
    static let shared = KeychainHelper()
    
    private init() {}
    
    // MARK: - Error Types
    
    enum KeychainError: Error, LocalizedError {
        case duplicateItem
        case itemNotFound
        case invalidData
        case unexpectedStatus(OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .duplicateItem:
                return "項目已存在"
            case .itemNotFound:
                return "找不到項目"
            case .invalidData:
                return "無效的資料格式"
            case .unexpectedStatus(let status):
                return "Keychain 錯誤：\(status)"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 儲存字串到 Keychain
    /// - Parameters:
    ///   - value: 要儲存的字串值
    ///   - key: 識別鍵
    /// - Throws: KeychainError
    func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        try save(data, forKey: key)
    }
    
    /// 儲存資料到 Keychain
    /// - Parameters:
    ///   - data: 要儲存的資料
    ///   - key: 識別鍵
    /// - Throws: KeychainError
    func save(_ data: Data, forKey key: String) throws {
        // 先嘗試刪除舊資料（如果存在）
        try? delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// 從 Keychain 讀取字串
    /// - Parameter key: 識別鍵
    /// - Returns: 儲存的字串值，如果不存在則返回 nil
    func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    /// 從 Keychain 讀取資料
    /// - Parameter key: 識別鍵
    /// - Returns: 儲存的資料，如果不存在則返回 nil
    func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return result as? Data
    }
    
    /// 從 Keychain 刪除項目
    /// - Parameter key: 識別鍵
    /// - Throws: KeychainError
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// 檢查 Keychain 中是否存在特定鍵
    /// - Parameter key: 識別鍵
    /// - Returns: 是否存在
    func exists(forKey key: String) -> Bool {
        return getData(forKey: key) != nil
    }
    
    /// 清除所有儲存的項目（謹慎使用）
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

// MARK: - Convenience Extensions

extension KeychainHelper {
    
    /// 儲存 SendGrid API Key
    /// - Parameter apiKey: API Key 字串
    /// - Throws: KeychainError
    func saveSendGridAPIKey(_ apiKey: String) throws {
        try save(apiKey, forKey: "sendgrid_api_key")
    }
    
    /// 讀取 SendGrid API Key
    /// - Returns: API Key 字串，如果不存在則返回 nil
    func getSendGridAPIKey() -> String? {
        return getString(forKey: "sendgrid_api_key")
    }
    
    /// 刪除 SendGrid API Key
    /// - Throws: KeychainError
    func deleteSendGridAPIKey() throws {
        try delete(forKey: "sendgrid_api_key")
    }
    
    /// 檢查是否已儲存 SendGrid API Key
    /// - Returns: 是否存在
    func hasSendGridAPIKey() -> Bool {
        return exists(forKey: "sendgrid_api_key")
    }
}
