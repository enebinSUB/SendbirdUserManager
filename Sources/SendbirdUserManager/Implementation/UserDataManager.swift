//
//  UserDataManager.swift
//
//
//  Created by YoungBin Lee on 12/27/23.
//

import Foundation

public class UserDataManager: SBUserManager {
    public let networkClient: SBNetworkClient
    public var userStorage: SBUserStorage
    
    private let rateLimiter: RateLimiter
    
    private var applicationId: String?
    private var apiToken: String?
    
    public required init() {
        self.networkClient = NetworkClientManager()
        self.userStorage = UserDataStorage()
        self.rateLimiter = RateLimiter(bucketCapacity: EnvironmentVariable.requestBucketLimit,
                                       throttleInterval: EnvironmentVariable.requestThrottleInterval)
    }

    public func initApplication(applicationId: String, apiToken: String) {
        if let previousApplicationId = self.applicationId, previousApplicationId != applicationId {
            userStorage = UserDataStorage()
        }
        
        EnvironmentVariable.applicationId = applicationId
        EnvironmentVariable.apiToken = apiToken
        
        self.applicationId = applicationId
        self.apiToken = apiToken
    }
    
    public func createUser(params: UserCreationParams, completionHandler: ((UserResult) -> Void)?) {
        rateLimiter.execute { [weak self] in
            guard let self else {
                completionHandler?(.failure(SBError.system(.selfDeallocated)))
                return
            }
            
            self.networkClient.request(request: UserRequest.create(params)) { result in
                switch result {
                case .success(let user):
                    // Update local cache
                    self.userStorage.upsertUser(user)
                    completionHandler?(.success(user))
                case .failure(let error):
                    completionHandler?(.failure(
                        SBError.user(.creationFail(underlying: error, affected: params))))
                }
            }
        } onError: { (error: SBError) in
            completionHandler?(.failure(error))
        }
    }
    
    public func createUsers(params: [UserCreationParams], completionHandler: ((UsersResult) -> Void)?) {
        guard params.count <= EnvironmentVariable.requestBucketLimit else {
            completionHandler?(.failure(SBError.user(.creationLimitExceeded)))
            return
        }
        
        var successfulUsers = [SBUser]()
        var creationFailures = [(params: UserCreationParams, error: Error)]()
        let dispatchGroup = DispatchGroup()
        
        params.forEach { param in
            dispatchGroup.enter()

            rateLimiter.execute { [weak self] in
                guard let self = self else {
                    completionHandler?(.failure(SBError.system(.selfDeallocated)))
                    return
                }
                
                self.networkClient.request(request: UserRequest.create(param)) { result in
                    switch result {
                    case .success(let user):
                        // Update local cache
                        self.userStorage.upsertUser(user)
                        successfulUsers.append(user)
                    case .failure(let error):
                        // Record the failure and the associated parameters.
                        creationFailures.append((param, error))
                    }
                    
                    dispatchGroup.leave()
                }
            } onError: { error in
                creationFailures.append((param, error))
            }
        }
        
        DispatchQueue.global(qos: .utility).async {
            // Set timeout assuming bad network
            _ = dispatchGroup.wait(timeout: .now() + 100)
            
            // Prioritize reporting any creation failures, returning an error if any occurred.
            if let error = creationFailures.first?.error {
                let affectedUsers = creationFailures.map { $0.params }
                completionHandler?(.failure(
                    SBError.user(.listCreationFail(underlying: error, affected: affectedUsers))))
                
                return
            }
            
            // If all operations succeeded, return the list of created users.
            // The list is sorted to match the order of the input parameters.
            let sortedSuccessfulUsers = successfulUsers.sorted(basedOnCreationParams: params)
            completionHandler?(.success(sortedSuccessfulUsers))
        }
    }
    
    public func getUser(userId: String, completionHandler: ((UserResult) -> Void)?) {
        if let cachedUser = userStorage.getUser(for: userId) {
            completionHandler?(.success(cachedUser))
        } else {
            rateLimiter.execute { [weak self] in
                guard let self else {
                    completionHandler?(.failure(SBError.system(.selfDeallocated)))
                    return
                }
                
                self.networkClient.request(request: UserRequest.getUser(byId: userId)) { response in
                    switch response {
                    case .success(let user):
                        // Update cache
                        self.userStorage.upsertUser(user)
                        completionHandler?(.success(user))
                    case .failure(let error):
                        completionHandler?(.failure(
                            SBError.user(.getFail(underlying: error, affectedUserId: userId))))
                    }
                }
            } onError: { (error: SBError) in
                completionHandler?(.failure(error))
            }
        }
    }
    
    public func getUsers(nicknameMatches: String, completionHandler: ((UsersResult) -> Void)?) {
        guard !nicknameMatches.isEmpty else {
            completionHandler?(.failure(SBError.userList(.emptyNicknamePattern)))
            return
        }
        
        let cachedUser = userStorage.getUsers(for: nicknameMatches)
        // Not only empty
        if !cachedUser.isEmpty {
            completionHandler?(.success(cachedUser))
        } else {
            rateLimiter.execute { [weak self] in
                guard let self else {
                    completionHandler?(.failure(SBError.system(.selfDeallocated)))
                    return
                }
                
                self.networkClient.request(request: UserListRequest.getUsersList) { response in
                    switch response {
                    case .success(let data):
                        let users = data.users
                        users.forEach {
                            // Update cache for each user
                            self.userStorage.upsertUser($0)
                        }
                        
                        let usersMathced = users.filter { $0.nickname == nicknameMatches }
                        completionHandler?(.success(usersMathced))
                    case .failure(let error):
                        completionHandler?(.failure(
                            SBError.userList(.getWithNicknameFail(underlying: error, nickname: nicknameMatches))))
                    }
                }
            } onError: { (error: SBError) in
                completionHandler?(.failure(error))
            }
        }
    }
    
    public func updateUser(params: UserUpdateParams, completionHandler: ((UserResult) -> Void)?) {
        rateLimiter.execute { [weak self] in
            guard let self else {
                completionHandler?(.failure(SBError.system(.selfDeallocated)))
                return
            }
            
            self.networkClient.request(request: UserRequest.update(params)) { result in
                switch result {
                case .success(let user):
                    // Update local cache
                    self.userStorage.upsertUser(user)
                    completionHandler?(.success(user))
                case .failure(let error):
                    completionHandler?(.failure(
                        SBError.user(.updateFail(underlying: error, affected: params))))
                }
            }
        } onError: { (error: SBError) in
            completionHandler?(.failure(error))
        }
    }
}
