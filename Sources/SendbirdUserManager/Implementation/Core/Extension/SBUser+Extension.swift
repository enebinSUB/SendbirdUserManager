//
//  SBUser+Extension.swift
//  
//
//  Created by YoungBin Lee on 12/28/23.
//

import Foundation

extension SBUser: Codable {
    enum CodingKeys: String, CodingKey {
         case userId = "user_id"
         case nickname
         case profileURL = "profile_url"
     }

     public init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         userId = try container.decode(String.self, forKey: .userId)
         nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
         profileURL = try container.decodeIfPresent(String.self, forKey: .profileURL)
     }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(nickname, forKey: .nickname)
        try container.encodeIfPresent(profileURL, forKey: .profileURL)
    }
}
