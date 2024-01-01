//
//  UserDataStorage.swift
//
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

public class UserDataStorage: SBUserStorage {
    private let synchronizationQueue = DispatchQueue(label: "UserDataStorage.synchronizationQueue",
                                                     qos: .utility,
                                                     attributes: .concurrent)
    
    private let cache: any KeyValueCaching<String, SBUser>
    
    public required init() {
        self.cache = LRUCache(capacityLimit: nil) // No capacity limit
    }
    
    public func upsertUser(_ user: SBUser) {
        synchronizationQueue.async(flags: .barrier) {
            self.cache.put(user.userId, user)
        }
    }
    
    public func getUsers() -> [SBUser] {
        synchronizationQueue.sync {
            self.cache.getAll()
        }
    }
    
    public func getUsers(for nickname: String) -> [SBUser] {
        synchronizationQueue.sync {
            self.cache.getAll().filter { $0.nickname == nickname }
        }
    }
    
    public func getUser(for userId: String) -> SBUser? {
        synchronizationQueue.sync {
            cache.get(userId)
        }
    }
}
