//
//  NetworkClientManager.swift
//
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

public class NetworkClientManager: SBNetworkClient {
    private let urlSession: URLSession
    private let requestTimeoutInterval: TimeInterval
    private let maxRetries: Int
    
    // For dependency injection
    init(
        urlSession: URLSession = .shared,
        requestTimeoutInterval: TimeInterval,
        maxRetries: Int
    ) {
        self.urlSession = urlSession
        self.requestTimeoutInterval = requestTimeoutInterval
        self.maxRetries = maxRetries
    }
    
    public required init() {
        self.urlSession = .shared
        self.requestTimeoutInterval = EnvironmentVariable.requestTimeoutInterval
        self.maxRetries = EnvironmentVariable.maxRetries
    }
    
    public func request<R: Request>(
        request: R,
        completionHandler: @escaping (Result<R.Response, Error>) -> Void
    ) where R: Request {
        guard let request = request as? URLRequestConvertible else {
            // Trigger fatal error due to it's indicating a critical implementation error
            // that must be resolved during development.
            fatalError("`Request` should also conform `URLRequestConvertible`")
        }
        
        do {
            guard let baseURL = baseURL(using: EnvironmentVariable.applicationId) else {
                throw SBError.network(.appplicationIdNotProvided)
            }
            
            guard let apiToken = EnvironmentVariable.apiToken else {
                throw SBError.network(.apiTokenNotProvided)
            }
            
            var urlRequest = try request.asURLRequest(with: baseURL)
            urlRequest.timeoutInterval = requestTimeoutInterval
            urlRequest.addValue(apiToken, forHTTPHeaderField: "Api-Token") // Add auth header
            
            let operation = NetworkOperation(urlRequest: urlRequest,
                                             completionHandler: completionHandler)
            sendRequest(operation)
        } catch {
            completionHandler(.failure(error))
        }
    }
}

private extension NetworkClientManager {
    func sendRequest(_ operation: NetworkOperation, retryCount: Int = 0) {
        let retry: (
            _ data: Data?,
            _ response: URLResponse?,
            _ error: Error?
        ) -> Void = { [weak self] data, response, error in
            guard let self else {
                operation.completionHandler(data, response, SBError.system(.selfDeallocated))
                return
            }
            
            if retryCount < maxRetries {
                // Exponential backoff: 2 ^ retryCount seconds
                let delay = pow(2.0, Double(retryCount))
                
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.sendRequest(operation, retryCount: retryCount + 1)
                }
            } else {
                // Retry limit reached, call the completion handler with the error
                operation.completionHandler(data,
                                            response,
                                            SBError.network(.retryLimitExceeded(underlying: error, trial: retryCount)))
            }
        }
        
        urlSession.dataTask(with: operation.urlRequest) { data, response, error in
            // Based on API guide(https://sendbird.com/docs/chat/platform-api/v3/error-codes),
            // retry when status code is 500
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 500 {
                retry(data, response, error)
            } else {
                operation.completionHandler(data, response, error)
            }
        }.resume()
    }
    
    func baseURL(using applicationId: String?) -> String? {
        if let applicationId {
            return "https://api-\(applicationId).sendbird.com/v3"
        } else {
            return nil
        }
    }
    
    /// Executes a network request and decodes the JSON response into a `Decodable` type.
    struct NetworkOperation {
        let urlRequest: URLRequest
        let completionHandler: (Data?, URLResponse?, Error?) -> Void
        
        init<Response>(
            urlRequest: URLRequest,
            completionHandler: @escaping (Result<Response, Error>) -> Void
        ) where Response: Decodable {
            self.urlRequest = urlRequest
            self.completionHandler = { data, response, error in
                if let error = error {
                    completionHandler(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completionHandler(.failure(URLError(.badServerResponse)))
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
                    completionHandler(.success(decodedResponse))
                } catch {
                    completionHandler(.failure(error))
                }
            }
        }
    }
}
