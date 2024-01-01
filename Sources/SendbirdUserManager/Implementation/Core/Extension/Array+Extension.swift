//
//  File.swift
//  
//
//  Created by 이영빈 on 1/1/24.
//

import Foundation

extension Array where Element == SBUser {
    func sorted(basedOnCreationParams creationParams: [UserCreationParams]) -> [SBUser] {
        // Create a mapping of userId to SBUser
        let userMap = Dictionary(uniqueKeysWithValues: self.map { ($0.userId, $0) })
        
        // Sort the users based on the order of userIds in creationParams
        let sortedUsers = creationParams.compactMap { params in
            userMap[params.userId]
        }
        
        return sortedUsers
    }
}
