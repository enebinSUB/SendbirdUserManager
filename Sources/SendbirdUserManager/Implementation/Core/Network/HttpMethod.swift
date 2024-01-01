//
//  HttpMethod.swift
//
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

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
