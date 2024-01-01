//
//  UserUpdateParams+Extension.swift
//  
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

extension UserUpdateParams: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(nickname, forKey: .nickname)
        try container.encodeIfPresent(profileURL, forKey: .profileURL)
    }
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname
        case profileURL = "profile_url"
    }
}
