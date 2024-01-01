//
//  RateLimiterTests.swift
//
//
//  Created by YoungBin Lee on 12/29/23.
//

import Foundation

import XCTest
@testable import SendbirdUserManager

class RateLimiterTests: XCTestCase {
    var rateLimiter: RateLimiter!
    
    override func setUpWithError() throws {
        rateLimiter = RateLimiter(bucketCapacity: 1, throttleInterval: 1)
    }
    
    func testRateLimiter() {
        rateLimiter = RateLimiter(bucketCapacity: 10, throttleInterval: 0.2)
        var executionCount = 0

        let expectation = XCTestExpectation(description: "Rate limiter should execute all operations with delays")

        
        for _ in 0..<10 {
            rateLimiter.execute {
                executionCount += 1
                if executionCount == 10 {
                    expectation.fulfill()
                }
            } onError: { _ in
                XCTFail("Error should not occur")
            }
        }

        wait(for: [expectation], timeout: 20)
        XCTAssertEqual(executionCount, 10, "All operations should be executed")
    }
    
    func testRateLimitGetHit() {
        rateLimiter = RateLimiter(bucketCapacity: 1, throttleInterval: 1)
        let expectation = XCTestExpectation(description: "Rate limiter should execute all operations with delays")
        
        rateLimiter.execute {
            // Do nothing
        } onError: { _ in
            XCTFail("Error should not occur")
        }
        
        rateLimiter.execute {
            // Do nothing
        } onError: { error in
            XCTAssertNotNil(error, "Second execute should get error because bucket capacity is set to 1")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)
    }
    
    func testRateLimiterThreadSafety() {
        let maxCapacity = 1000
        
        rateLimiter = RateLimiter(bucketCapacity: maxCapacity, throttleInterval: 0)
        var executionCount = 0
        let expectation = XCTestExpectation(description: "Rate limiter should handle concurrent operations")
        expectation.expectedFulfillmentCount = maxCapacity

        for _ in 0..<maxCapacity {
            DispatchQueue.global().async {
                self.rateLimiter.execute {
                    executionCount += 1
                    expectation.fulfill()
                } onError: { error in
                    XCTFail("Error should not occur")
                }
            }
        }

        wait(for: [expectation], timeout: 20)
        XCTAssertEqual(executionCount, maxCapacity, "All operations should be executed")
    }
}
