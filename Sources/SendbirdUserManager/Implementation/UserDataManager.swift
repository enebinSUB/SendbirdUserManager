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
        
        Logger.shared.info("UserDataManager initialization successful. Ready for further operations.")
    }
    
    public func createUser(params: UserCreationParams, completionHandler: ((UserResult) -> Void)?) {
        rateLimiter.execute { [weak self] in
            guard let self else {
                completionHandler?(.failure(SBError.system(.selfDeallocated)))
                Logger.shared.error("UserDataManager instance was deallocated during user creation.")
                return
            }
            
            self.networkClient.request(request: UserRequest.create(params)) { result in
                switch result {
                case .success(let user):
                    // Update local cache
                    self.userStorage.upsertUser(user)
                    completionHandler?(.success(user))
                    
                    Logger.shared.info("Successfully created user with id: \(user.userId)")

                case .failure(let error):
                    completionHandler?(.failure(
                        SBError.user(.creationFail(underlying: error, affected: params))))
                    
                    Logger.shared.error("Failed to create user: \(error.localizedDescription)")
                }
            }
        } onError: { (error: SBError) in
            completionHandler?(.failure(error))
            Logger.shared.error("Rate limiter error during user creation: \(error.localizedDescription)")
        }
    }
    
    public func createUsers(params: [UserCreationParams], completionHandler: ((UsersResult) -> Void)?) {
        guard params.count <= EnvironmentVariable.requestBucketLimit else {
            completionHandler?(.failure(SBError.user(.creationLimitExceeded)))
            Logger.shared.error("User creation limit exceeded. Attempted to create \(params.count) users; limit is \(EnvironmentVariable.requestBucketLimit).")
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
                    Logger.shared.error("UserDataManager instance was deallocated during batch user creation.")
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
                        Logger.shared.error("Failed to create user with params: \(param). Error: \(error.localizedDescription)")
                    }
                    
                    dispatchGroup.leave()
                }
            } onError: { error in
                creationFailures.append((param, error))
                Logger.shared.error("Rate limiter error during batch user creation for params: \(param). Error: \(error.localizedDescription)")
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
                Logger.shared.error("Failed to create user list. Affected user: \(affectedUsers). Error: \(error.localizedDescription)")
                return
            }
            
            // If all operations succeeded, return the list of created users.
            // The list is sorted to match the order of the input parameters.
            let sortedSuccessfulUsers = successfulUsers.sorted(basedOnCreationParams: params)
            completionHandler?(.success(sortedSuccessfulUsers))
            Logger.shared.info("Successfully created \(sortedSuccessfulUsers.count) users.")
        }
    }

    public func getUser(userId: String, completionHandler: ((UserResult) -> Void)?) {
        if let cachedUser = userStorage.getUser(for: userId) {
            completionHandler?(.success(cachedUser))
            Logger.shared.info("Retrieved user with ID '\(userId)' from cache.")
        } else {
            rateLimiter.execute { [weak self] in
                guard let self else {
                    completionHandler?(.failure(SBError.system(.selfDeallocated)))
                    Logger.shared.error("UserDataManager instance was deallocated during user retrieval for ID '\(userId)'.")
                    return
                }
                
                self.networkClient.request(request: UserRequest.getUser(byId: userId)) { response in
                    switch response {
                    case .success(let user):
                        // Update cache
                        self.userStorage.upsertUser(user)
                        completionHandler?(.success(user))
                        Logger.shared.info("Successfully retrieved user with ID '\(userId)' from network and updated cache.")

                    case .failure(let error):
                        completionHandler?(.failure(
                            SBError.user(.getFail(underlying: error, affectedUserId: userId))))
                        Logger.shared.error("Failed to retrieve user with ID '\(userId)'. Error: \(error.localizedDescription)")
                    }
                }
            } onError: { (error: SBError) in
                completionHandler?(.failure(error))
                Logger.shared.error("Rate limiter error during user retrieval for ID '\(userId)'. Error: \(error.localizedDescription)")
            }
        }
    }
    
    public func getUsers(nicknameMatches: String, completionHandler: ((UsersResult) -> Void)?) {
        guard !nicknameMatches.isEmpty else {
            completionHandler?(.failure(SBError.userList(.emptyNicknamePattern)))
            Logger.shared.error("Failed to get users: Nickname pattern is empty.")
            return
        }
        
        let cachedUsers = userStorage.getUsers(for: nicknameMatches)
        if !cachedUsers.isEmpty {
            completionHandler?(.success(cachedUsers))
            Logger.shared.info("Retrieved users with nickname matching '\(nicknameMatches)' from cache.")
        } else {
            rateLimiter.execute { [weak self] in
                guard let self else {
                    completionHandler?(.failure(SBError.system(.selfDeallocated)))
                    Logger.shared.error("UserDataManager instance was deallocated during retrieval of users with nickname '\(nicknameMatches)'.")
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
                        
                        let usersMatched = users.filter { $0.nickname == nicknameMatches }
                        completionHandler?(.success(usersMatched))
                        Logger.shared.info("Retrieved users with nickname matching '\(nicknameMatches)' from network and updated cache.")

                    case .failure(let error):
                        completionHandler?(.failure(
                            SBError.userList(.getWithNicknameFail(underlying: error, nickname: nicknameMatches))))
                        Logger.shared.error("Failed to retrieve users with nickname matching '\(nicknameMatches)'. Error: \(error.localizedDescription)")
                    }
                }
            } onError: { (error: SBError) in
                completionHandler?(.failure(error))
                Logger.shared.error("Rate limiter error during retrieval of users with nickname '\(nicknameMatches)'. Error: \(error.localizedDescription)")
            }
        }
    }
    
    public func updateUser(params: UserUpdateParams, completionHandler: ((UserResult) -> Void)?) {
        rateLimiter.execute { [weak self] in
            guard let self else {
                completionHandler?(.failure(SBError.system(.selfDeallocated)))
                Logger.shared.error("UserDataManager instance was deallocated during user update.")
                return
            }
            
            self.networkClient.request(request: UserRequest.update(params)) { result in
                switch result {
                case .success(let user):
                    // Update local cache
                    self.userStorage.upsertUser(user)
                    completionHandler?(.success(user))
                    Logger.shared.info("Successfully updated user with ID '\(user.userId)'.")

                case .failure(let error):
                    completionHandler?(.failure(
                        SBError.user(.updateFail(underlying: error, affected: params))))
                    Logger.shared.error("Failed to update user. Error: \(error.localizedDescription)")
                }
            }
        } onError: { (error: SBError) in
            completionHandler?(.failure(error))
            Logger.shared.error("Rate limiter error during user update. Error: \(error.localizedDescription)")
        }
    }

}
