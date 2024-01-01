//
//  LRUCache.swift
//
//
//  Created by 이영빈 on 1/1/24.
//

import Foundation

/// LRU Cache is NOT thread-safe
class LRUCache<Key, Value>: KeyValueCaching where Key: Hashable {
    let capacityLimit: Int?
    private var count = 0
    
    private var head: Node
    private var tail: Node
    
    private var cache = [Key: Node]()
    
    init(capacityLimit: Int?) {
        self.capacityLimit = capacityLimit
        
        self.head = Node(nil, nil)
        self.tail = Node(nil, nil)
        
        head.next = tail
        tail.prev = head
    }
    
    func get(_ key: Key) -> Value? {
        if let node = cache[key] {
            moveHead(node)
            return node.val
        } else {
            return nil
        }
    }
    
    func put(_ key: Key, _ value: Value) {
        if let node = cache[key] {
            node.val = value
            moveHead(node)
        } else {
            let node = Node(key, value)
            
            cache[key] = node
            add(node)
            count += 1
            
            if let capacityLimit, count > capacityLimit {
                let popped = popTail()
                if let poppedKey = popped.key {
                    cache.removeValue(forKey: poppedKey)
                }
                self.count -= 1
            }
        }
    }
    
    func getAll() -> [Value] {
        var allUsers = [Value]()
        var currentNode = head.next
        
        while let node = currentNode, node !== tail {
            if let user = node.val {
                allUsers.append(user)
            }
            currentNode = node.next
        }
        
        return allUsers
    }
}

private extension LRUCache {
    class Node {
        var next: Node?
        var prev: Node?
        var key: Key?
        var val: Value?
        
        init(_ key: Key?, _ val: Value?) {
            self.key = key
            self.val = val
        }
    }
    
    func remove(_ node: Node) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
    }
    
    func add(_ node: Node) {
        node.prev = head
        node.next = head.next
        
        head.next?.prev = node
        head.next = node
    }
    
    func moveHead(_ node: Node) {
        remove(node)
        add(node)
    }
    
    func popTail() -> Node {
        let result = tail.prev!
        remove(result)
        
        return result
    }
}
