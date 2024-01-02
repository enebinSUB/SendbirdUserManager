//
//  SBError.swift
//
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

enum SBError: LocalizedError {
    case user(UserFailureReason)
    case userList(UserListFailureReason)
    case system(SystemFailureReason)
    case network(NetworkFailureReason)
    
    var errorDescription: String? {
        switch self {
        case .user(let reason):
            return reason.description
        case .userList(let reason):
            return reason.description
        case .system(let reason):
            return reason.description
        case .network(let reason):
            return reason.description
        }
    }
}

extension SBError {
    enum UserFailureReason {
        case creationLimitExceeded
        case creationFail(underlying: Error, affected: UserCreationParams)
        case listCreationFail(underlying: Error, affected: [UserCreationParams])
        case updateFail(underlying: Error, affected: UserUpdateParams)
        case getFail(underlying: Error, affectedUserId: String)
        
        var description: String {
            switch self {
            case .creationLimitExceeded:
                return "User creation limit exceeded."
            case .creationFail(let underlyingError, let affected):
                return "Failed to create user \(affected.userId). Reason: \(underlyingError.localizedDescription)"
            case .listCreationFail(let underlyingError, let affected):
                let affectedUserIds = affected.map { $0.userId }.joined(separator: ", ")
                return "Failed to create users with IDs: \(affectedUserIds). Reason: \(underlyingError.localizedDescription)"
            case .updateFail(let underlyingError, let affected):
                return "Failed to update user \(affected.userId). Reason: \(underlyingError.localizedDescription)"
            case .getFail(let underlyingError, let affectedUserId):
                return "Failed to get user \(affectedUserId). Reason: \(underlyingError.localizedDescription)"
            }
        }
    }
    
    enum UserListFailureReason {
        case getWithNicknameFail(underlying: Error, nickname: String)
        case emptyNicknamePattern
        var description: String {
            switch self {
            case .getWithNicknameFail(let underlyingError, let nickname):
                return "Failed to get user with nickname \(nickname). Reason: \(underlyingError.localizedDescription)"
            case .emptyNicknamePattern:
                return "Nickname pattern shouldn't be empty."
            }
        }
    }
    
    enum SystemFailureReason {
        case requestRateHitLimit(_ throttleInterval: TimeInterval, _ bucketCapacity: Int)
        case selfDeallocated
        var description: String {
            switch self {
            case let .requestRateHitLimit(throttleInterval, bucketCapacity):
                return "Request rate limit hit. Throttle Interval: \(throttleInterval) seconds, Bucket Capacity: \(bucketCapacity)"
            case .selfDeallocated:
                return "Instance was deallocated before the request could be processed."
            }
        }
    }
    
    enum NetworkFailureReason {
        case retryLimitExceeded(underlying: Error?, trial: Int)
        case apiTokenNotProvided
        case applicationIdNotProvided
        var description: String {
            switch self {
            case let .retryLimitExceeded(underlyingError, trial):
                let errorDescription = underlyingError?.localizedDescription ?? "Unknown error"
                return "Network request retry limit (\(trial)) exceeded. Reason: \(errorDescription)"
            case .apiTokenNotProvided:
                return "API token is not provided."
            case .applicationIdNotProvided:
                return "Application ID is not provided."
            }
        }
    }
}
