//
//  EnvironmentVariable.swift
//
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

/// Environment variable is basically thread-safe
struct EnvironmentVariable {
    // MARK: - Constant values
    static let requestBucketLimit = 10
    static let requestTimeoutInterval: TimeInterval = 20
    static let maxRetries: Int = 3
    static let requestThrottleInterval: TimeInterval = 1

    // MARK: - Variable values, atomic
    private static let synchronizationQueue = DispatchQueue(label: "EnvironmentVariable.synchronizationQueue")

    private static var _apiToken: String?
    static var apiToken: String? {
        get {
            return synchronizationQueue.sync {
                _apiToken
            }
        }
        set {
            synchronizationQueue.async(flags: .barrier) {
                _apiToken = newValue
            }
        }
    }

    private static var _applicationId: String?
    static var applicationId: String? {
        get {
            return synchronizationQueue.sync {
                _applicationId
            }
        }
        set {
            synchronizationQueue.async(flags: .barrier) {
                _applicationId = newValue
            }
        }
    }
}
