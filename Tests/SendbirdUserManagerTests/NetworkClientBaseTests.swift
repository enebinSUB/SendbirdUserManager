//
//  NetworkClientManagerTests.swift
//
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

import XCTest
@testable import SendbirdUserManager

// Used local mocking intead of overriden class
class NetworkClientBaseTests: XCTestCase {
    private var mockURLSession: MockURLSession!
    
    override func setUpWithError() throws {
        mockURLSession = MockURLSession()
        EnvironmentVariable.applicationId = "applicationId"
        EnvironmentVariable.apiToken = "apiToken"
    }
    
    func testRequestProcessing() {
        let networkClientManager = NetworkClientManager(urlSession: mockURLSession,
                                                        requestTimeoutInterval: 10,
                                                        maxRetries: 3)
        let mockRequest = MockRequest()
        
        let expectation = self.expectation(description: "Process Request")
        networkClientManager.request(request: mockRequest) { _ in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
        
        // Verify that the request was sent
        XCTAssertNotNil(mockURLSession.lastURLRequest, "Request should have been sent")
    }
    
    func testErrorHandling() {
        let networkClientManager = NetworkClientManager(urlSession: mockURLSession,
                                                        requestTimeoutInterval: 10,
                                                        maxRetries: 3)
        
        let mockRequest = MockRequest() // This should be set up to fail
        
        let expectation = self.expectation(description: "Error Handling")
        networkClientManager.request(request: mockRequest) { result in
            if case .failure(let error) = result {
                // Check if error is as expected
                XCTAssertNotNil(error, "Error should be present")
            } else {
                XCTFail("Expected failure, but request succeeded")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testRetryLogic() {
        let networkClientManager = NetworkClientManager(urlSession: mockURLSession,
                                                        requestTimeoutInterval: 10,
                                                        maxRetries: 3)
        
        let expectation = self.expectation(description: "Retry Logic Test")
        var retryCount = 0
        
        mockURLSession.responseHandler = { request in
            retryCount += 1
            if retryCount <= 3 {
                return (
                    nil,
                    HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil),
                    nil)
            } else {
                return (
                    try! JSONEncoder().encode("Data"),
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil),
                    nil)
            }
        }
        
        networkClientManager.request(request: MockRequest()) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Request failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 20)
        XCTAssertEqual(retryCount, 4, "There should be 3 retries before success")
    }
}

// MARK: - Mockers
fileprivate class MockURLSession: URLSession {
    var lastURLRequest: URLRequest?
    var responseHandler: ((URLRequest) -> (Data?, URLResponse?, Error?))?
        
    override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        lastURLRequest = request
        
        let response = responseHandler?(request)
        completionHandler(response?.0, response?.1, response?.2)
        
        return MockURLSessionDataTask()
    }
}

fileprivate final class MockURLSessionDataTask: URLSessionDataTask {
    override func resume() {}
}

fileprivate struct MockRequest: Request {
    typealias Response = String
}

extension MockRequest: URLRequestConvertible {
    var baseURL: String {
        "www.example.io"
    }
    
    var path: String {
        "example"
    }
    
    var httpMethod: SendbirdUserManager.HTTPMethod {
        .get
    }
}
