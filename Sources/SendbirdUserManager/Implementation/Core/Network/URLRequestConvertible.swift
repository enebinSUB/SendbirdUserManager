//
//  URLRequestConvertible.swift
//
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

/// Protocol to define the requirements for converting an object into a URLRequest.
protocol URLRequestConvertible {
    /// The path component of the URL.
    var path: String { get }
    
    /// Dictionary containing header fields for the request.
    var header: [String: String] { get }
    
    /// Array of URL query items (parameters) for the request.
    var queries: [URLQueryItem] { get }
    
    /// HTTP method (e.g., GET, POST) for the request.
    var httpMethod: HTTPMethod { get }
    
    /// Function to create a URLRequest using a base URL.
    func asURLRequest(with baseURL: String) throws -> URLRequest
}

extension URLRequestConvertible {
    var queries: [URLQueryItem] { [] }
    var header: [String : String] { [:] }

    // Default implementation to convert the current object into a URLRequest.
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
