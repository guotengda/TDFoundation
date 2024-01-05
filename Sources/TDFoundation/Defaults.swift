//
//  Defaults.swift
//  
//
//  Created by Sherlock on 2024/1/5.
//

import Foundation
import TDStability

/// Represents a 'TDDefaultsKey' with an associated generic value type confirming to the 'Codable' protocol
///
///     static let someKey = Key<ValyeType>("someKey")
public struct TDDefaultsKey<ValueType: Codable> {
    
    fileprivate let key: String
    
    public init(_ key: String) { self.key = key }
}

/// Provides strongly typed values associated with the lifetime of an application. Apropriate for user perferences
/// - Warning
///     these should not be used to store sensitive information that could compromise
///     the application or the user's security and privacy
public struct TDDefaults {
    
    private var userDefaults: UserDefaults
    
    /// Shared instance of 'TDDefaults'. used for ad-hoc access to the user's defaults database throughout the app
    public static let shared = TDDefaults.init()
    
    /// An instance of 'TDDefaults' with the specified 'UserDefaults' instance
    ///
    /// - Parameter userDefaults: the userDefaults
    public init(userDefaults: UserDefaults = UserDefaults.standard) { self.userDefaults = userDefaults }
    
    /// Deletes the value associated with the specified key, if any
    ///
    /// - Parameter key: the key
    public func clear<ValueType>(_ key: TDDefaultsKey<ValueType>) {
        userDefaults.do {
            $0.set(nil, forKey: key.key)
            $0.synchronize()
        }
    }
    
    /// Checks if there is a value associated with the specified key
    ///
    /// - Parameter key: the key to look for
    /// - Returns: a boolean value indicating if a value exists for the specified key
    public func has<ValueType>(_ key: TDDefaultsKey<ValueType>) -> Bool { return userDefaults.value(forKey: key.key) != nil }
    
    /// Returns the value asspciated with the specified key
    ///
    /// - Parameter key: the key
    /// - Returns: a 'ValueType' or nil if the key was not found
    public func get<ValueType>(for key: TDDefaultsKey<ValueType>) -> ValueType? {
        if isSwiftCodableType(ValueType.self) || isFoundationCodableType(ValueType.self) {
            return userDefaults.value(forKey: key.key) as? ValueType
        } else {
            guard let data = userDefaults.data(forKey: key.key) else { return nil }
            
            do {
                return try JSONDecoder.init().decode(ValueType.self, from: data)
            } catch {
                #if DEBUG
                Logger.error(error.localizedDescription)
                #endif
            }
            
            return nil
        }
    }
    
    /// Sets a value associated with the specified key
    ///
    /// - Parameters:
    ///   - value: the value to set
    ///   - key: the associated 'Key<ValueType>'
    public func set<ValueType>(_ value: ValueType, for key: TDDefaultsKey<ValueType>) {
        if isSwiftCodableType(ValueType.self) || isFoundationCodableType(ValueType.self) {
            userDefaults.set(value, forKey: key.key)
        } else {
            do {
                userDefaults.set(try JSONEncoder.init().encode(value), forKey: key.key)
                userDefaults.synchronize()
            } catch {
                #if DEBUG
                Logger.error(error.localizedDescription)
                #endif
            }
        }
    }
    
    /// Checks if the specified type is a Codable from the Swift standard library
    ///
    /// - Parameter type: the type need be checked
    private func isSwiftCodableType<ValueType>(_ type: ValueType.Type) -> Bool {
        switch type {
        case is String.Type, is Bool.Type, is Int.Type, is Float.Type, is Double.Type: return true
        default: return false
        }
    }
    
    /// Check if the specified type is a Codable, from the Swift;s core libraries
    /// Foundation.framework
    ///
    /// - Parameter type: the type need be checked
    private func isFoundationCodableType<ValueType>(_ type: ValueType.Type) -> Bool {
        switch type {
        case is Date.Type: return true
        case is Data.ReferenceType.Type: return true
        case is Foundation.Data.Type: return true
        default: return false
        }
    }
}
