//
//  KeyValueCaching.swift
//
//
//  Created by 이영빈 on 1/1/24.
//

import Foundation

/// Protocol defining a generic key-value caching system.
protocol KeyValueCaching<KeyType, ValueType> where KeyType: Hashable {
    associatedtype KeyType
    associatedtype ValueType
    
    /// The maximum number of items the cache can hold.
    /// If set to `nil`, the cache has no predefined limit.
    var capacityLimit: Int? { get }
    
    /// Retrieves the value associated with the given key, if it exists in the cache
    func get(_ key: KeyType) -> ValueType?
    
    /// Inserts or updates a value in the cache with the given key
    func put(_ key: KeyType, _ value: ValueType)
    
    /// Retrieves all values currently stored in the cache.
    func getAll() -> [ValueType]
}
