//
//  UsersRequest.swift
//
//
//  Created by YoungBin Lee on 12/28/23.
//

import Foundation


enum UserListRequest: Request {
    typealias Response = UserListRequestResponse
    
    /// Get all users list
    case getUsersList
}

struct UserListRequestResponse: Decodable {
    let users: [SBUser]
}

extension UserListRequest: URLRequestConvertible {    
    var path: String {
        switch self {
        case .getUsersList:
            return "users"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .getUsersList:
            return .get
        }
    }
    
    var queries: [URLQueryItem] {
        switch self {
        case .getUsersList:
            return [URLQueryItem(name: "limit", value: "10")]
        }
    }
}
