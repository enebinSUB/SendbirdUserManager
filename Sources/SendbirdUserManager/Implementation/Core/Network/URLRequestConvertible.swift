//
//  URLRequestConvertible.swift
//
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

protocol URLRequestConvertible {
    var path: String { get }
    var header: [String: String] { get } 
    var queries: [URLQueryItem] { get }
    var httpMethod: HTTPMethod { get }
    
    func asURLRequest(with baseURL: String) throws -> URLRequest
}

extension URLRequestConvertible {
    var queries: [URLQueryItem] { [] }
    var header: [String : String] { [:] }
    
    func asURLRequest(with baseURL: String) throws -> URLRequest {
        guard var urlComponent = URLComponents(string: baseURL) else {
            fatalError("Base URL is not valid")
        }
        
        urlComponent.path += "/" + path
        urlComponent.queryItems = queries
        
        guard let requestUrl = urlComponent.url else {
            fatalError("Transformed URL is not valid")
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = httpMethod.stringValue
        header.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let encoder = JSONEncoder()
        switch httpMethod {
        case .post(let body):
            request.httpBody = try encoder.encode(body)
        case .put(let body):
            request.httpBody = try encoder.encode(body)
        default:
            break
        }
        
        return request
    }
}
