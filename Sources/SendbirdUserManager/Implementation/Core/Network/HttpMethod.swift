//
//  HttpMethod.swift
//
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

/// HTTP methods enumeration used for network request
/// Currently supports `get`, `post`, `put` only.
enum HTTPMethod {
    case get
    case post(body: Encodable)
    case put(body: Encodable)
    
    var stringValue: String {
        switch self {
        case .get: return "GET"
        case .put: return "PUT"
        case .post: return "POST"
        }
    }
}
