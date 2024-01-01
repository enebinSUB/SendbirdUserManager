//
//  UserCreationParams+Extension.swift
//  
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

extension UserCreationParams: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(profileURL, forKey: .profileURL)
        try container.encode(false, forKey: .issueAccessToken) // Manually encode the additional field
    }

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname
        case profileURL = "profile_url"
        case issueAccessToken = "issue_access_token"
    }
}
