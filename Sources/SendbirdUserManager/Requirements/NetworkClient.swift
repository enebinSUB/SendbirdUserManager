//
//  NetworkClient.swift
//  
//
//  Created by Sendbird
//

import Foundation

public protocol Request {
    // 네트워크 응답 처리의 용이성을 위해 부득이 `Decodable`을 추가하게 되었습니다.
    associatedtype Response: Decodable
}

public protocol SBNetworkClient {
    init()
    
    /// 리퀘스트를 요청하고 리퀘스트에 대한 응답을 받아서 전달합니다
    func request<R: Request>(
        request: R,
        completionHandler: @escaping (Result<R.Response, Error>) -> Void
    )
}
