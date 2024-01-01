//
//  RateLimiter.swift
//
//
//  Created by YoungBin Lee on 12/29/23.
//

import Foundation

/// A rate limiter class that controls the execution of operations based on a leaky bucket algorithm.
/// It ensures that the operations do not exceed a specified rate limit and also thread-safe.
final class RateLimiter {
    typealias Operation = () -> Void
    
    private let workQueue = DispatchQueue(label: "RateLimiter.workQueue", qos: .utility)
    private let leakQueue = DispatchQueue(label: "RateLimiter.leakQueue", qos: .background)
    
    private let throttleInterval: TimeInterval
    private let bucketCapacity: Int
    private var currentlyContainingOperations: Int
    
    private var queuedOperations: [Operation] = []
    
    private var isRequestInProgress = false
    
    init(bucketCapacity: Int, throttleInterval: TimeInterval) {
        self.bucketCapacity = bucketCapacity
        self.currentlyContainingOperations = 0
        self.throttleInterval = throttleInterval
    }
    
    func execute(operation: @escaping Operation, onError: ((SBError) -> Void)? = nil) {
        workQueue.async {
            if self.currentlyContainingOperations < self.bucketCapacity {
                self.queuedOperations.append(operation)
                self.currentlyContainingOperations += 1

                self.processNextOperation()
            } else {
                onError?(SBError.system(.requestRateHitLimit(self.throttleInterval, self.bucketCapacity)))
            }
        }
    }
}

private extension RateLimiter {
    func processNextOperation() {
        guard !isRequestInProgress, !queuedOperations.isEmpty else {
            return
        }
        self.isRequestInProgress = true

        let operation = queuedOperations.removeFirst()
        operation()

        leakQueue.async {
            Timer.scheduledTimer(withTimeInterval: self.throttleInterval, repeats: false) { _ in
                self.isRequestInProgress = false
                self.currentlyContainingOperations -= 1
                
                self.workQueue.async {
                    self.processNextOperation()
                }
            }
            RunLoop.current.run()
        }
    }
}
