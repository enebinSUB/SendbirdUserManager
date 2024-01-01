//
//  UserRequest.swift
//  
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

enum UserRequest: Request {
    typealias Response = SBUser
    
    /// Create an user
    case create(UserCreationParams)
    /// Update the user info
    case update(UserUpdateParams)
    /// Get the user using userId
    case getUser(byId: String)
}

extension UserRequest: URLRequestConvertible {
    var path: String {
        switch self {
        case .create:
            return "users"
        case .update(let params):
            return "users/\(params.userId)"
        case .getUser(let id):
            return "users/\(id)"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .create(let params):
            return .post(body: params)
        case .update(let params):
            return .put(body: params)
        case .getUser:
            return .get
        }
    }
}
