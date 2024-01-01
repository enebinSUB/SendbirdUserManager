//
//  KeyValueCaching.swift
//
//
//  Created by 이영빈 on 1/1/24.
//

import Foundation

protocol KeyValueCaching<KeyType, ValueType> where KeyType: Hashable {
    associatedtype KeyType
    associatedtype ValueType
    
    /// Set `capacity` to `nil` if do not want to define the limit
    var capacityLimit: Int? { get }
    
    func get(_ key: KeyType) -> ValueType?
    func put(_ key: KeyType, _ value: ValueType)
    func getAll() -> [ValueType]
}
