//
//  LRUCacheTests.swift
//
//
//  Created by 이영빈 on 1/1/24.
//

import XCTest
@testable import SendbirdUserManager

class LRUCacheTests: XCTestCase {
    var lruCache: LRUCache<String, String>!

    override func setUpWithError() throws {
        lruCache = LRUCache(capacityLimit: 3)
    }

    override func tearDownWithError() throws {
        lruCache = nil
    }

    func testAddAndGet() {
        lruCache.put("user1", "UserData1")
        XCTAssertEqual(lruCache.get("user1"), "UserData1")
    }

    func testLRUEviction() {
        lruCache.put("user1", "UserData1")
        lruCache.put("user2", "UserData2")
        lruCache.put("user3", "UserData3")
        lruCache.put("user4", "UserData4") // This should evict "user1"

        XCTAssertNil(lruCache.get("user1"))
        XCTAssertNotNil(lruCache.get("user2"))
    }

    func testOrderAfterAccess() {
        lruCache.put("user1", "UserData1")
        lruCache.put("user2", "UserData2")

        // Access user1 to move it to the head
        _ = lruCache.get("user1")

        let allUsers = lruCache.getAll()
        XCTAssertEqual(allUsers.first, "UserData1")
    }

    func testGetAll() {
        lruCache.put("user1", "UserData1")
        lruCache.put("user2", "UserData2")

        let allUsers = lruCache.getAll()
        XCTAssertEqual(allUsers.count, 2)
    }
}
