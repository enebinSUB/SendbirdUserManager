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
                return "Failed to create the user \(affected.userId)."
                        + "\nReason: \(underlyingError)"
            case .listCreationFail(let underlyingError, let affected):
                return "Failed to create the users \(affected.map { $0.userId }). Other users are created succeessfully"
                        + "\nReason: \(underlyingError)"
            case .updateFail(let underlyingError, let affected):
                return "Failed to update the user \(affected.userId)."
                        + "\nReason: \(underlyingError)"
            case .getFail(let underlyingError, let affectedUserId):
                return "Failed to get the user \(affectedUserId)"
                        + "\nReason: \(underlyingError)"
            }
        }
    }
    
    enum UserListFailureReason {
        case getWithNicknameFail(underlying: Error, nickname: String)
        case emptyNicknamePattern
        var description: String {
            switch self {
            case .getWithNicknameFail(let underlyingError, let nickname):
                return "Failed to get the user nickname matching \(nickname)."
                        + "\nReason: \(underlyingError)"
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
                return "Request rate limit has been hit."
                        + "(Throttle Interval: \(throttleInterval) seconds, Bucket Capacity: \(bucketCapacity))"
            case .selfDeallocated:
                return "Instance was deallocated before the request could be processed."
            }
        }
    }
    
    enum NetworkFailureReason {
        case retryLimitExceeded(underlying: Error?, trial: Int)
        case apiTokenNotProvided
        case appplicationIdNotProvided
        var description: String {
            switch self {
            case let .retryLimitExceeded(underlyingError, trial):
                return "Network request retry limit(\(trial)) exceeded."
                        + "\nReason: \(underlyingError?.localizedDescription ?? String("none"))"
                
            case .apiTokenNotProvided:
                return "API token is not provided."
            
            case .appplicationIdNotProvided:
                return "Application ID is not provided."
            }
        }
    }
}
