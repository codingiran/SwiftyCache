@testable import SwiftyCache
import XCTest

final class SwiftyCacheTests: XCTestCase {
    private var cache: SwiftyCache<String, String>!
    
    override func setUp() async throws {
        cache = SwiftyCache(totalCostLimit: 100, countLimit: 5)
    }
    
    override func tearDown() async throws {
        await cache.removeAllValues()
        cache = nil
    }
    
    // MARK: - Basic Operation Tests
    
    func testSetAndGetValue() async throws {
        await cache.setValue("value1", forKey: "key1")
        let value = await cache.value(forKey: "key1")
        XCTAssertEqual(value, "value1")
    }
    
    func testSetNilRemovesValue() async throws {
        await cache.setValue("value1", forKey: "key1")
        await cache.setValue(nil, forKey: "key1")
        let value = await cache.value(forKey: "key1")
        XCTAssertNil(value)
    }
    
    func testRemoveValue() async throws {
        await cache.setValue("value1", forKey: "key1")
        let removed = await cache.removeValue(forKey: "key1")
        let value = await cache.value(forKey: "key1")
        XCTAssertEqual(removed, "value1")
        XCTAssertNil(value)
    }
    
    func testRemoveAllValues() async throws {
        await cache.setValue("value1", forKey: "key1")
        await cache.setValue("value2", forKey: "key2")
        await cache.removeAllValues()
        let isEmpty = await cache.isEmpty
        let totalCost = await cache.totalCost
        XCTAssertTrue(isEmpty)
        XCTAssertEqual(totalCost, 0)
    }
    
    // MARK: - Cost Tests
    
    func testTotalCostLimit() async throws {
        await cache.setValue("value1", forKey: "key1", cost: 60)
        await cache.setValue("value2", forKey: "key2", cost: 50)
        // Should remove key1 due to cost limit
        let value1 = await cache.value(forKey: "key1")
        let value2 = await cache.value(forKey: "key2")
        let totalCost = await cache.totalCost
        XCTAssertNil(value1)
        XCTAssertEqual(value2, "value2")
        XCTAssertLessThanOrEqual(totalCost, 100)
    }
    
    func testCountLimit() async throws {
        for i in 1 ... 6 {
            await cache.setValue("value\(i)", forKey: "key\(i)")
        }
        // Should have removed the oldest entry
        let value = await cache.value(forKey: "key1")
        let count = await cache.count
        XCTAssertNil(value)
        XCTAssertLessThanOrEqual(count, 5)
    }
    
    // MARK: - Property Tests
    
    func testIsEmpty() async throws {
        let emptyAtStart = await cache.isEmpty
        XCTAssertTrue(emptyAtStart)
        
        await cache.setValue("value1", forKey: "key1")
        let emptyAfterInsert = await cache.isEmpty
        XCTAssertFalse(emptyAfterInsert)
    }
    
    func testAllKeysAndValues() async throws {
        await cache.setValue("value1", forKey: "key1")
        await cache.setValue("value2", forKey: "key2")
        
        let keys = await cache.allKeys
        let values = await cache.allValues
        
        XCTAssertEqual(keys, ["key1", "key2"])
        XCTAssertEqual(values, ["value1", "value2"])
    }
    
    // MARK: - LRU Tests
    
    func testLRUBehavior() async throws {
        await cache.setValue("value1", forKey: "key1")
        await cache.setValue("value2", forKey: "key2")
        
        // Access key1 to make it most recently used
        _ = await cache.value(forKey: "key1")
        
        // Add more items to trigger eviction
        await cache.setValue("value3", forKey: "key3")
        await cache.setValue("value4", forKey: "key4")
        await cache.setValue("value5", forKey: "key5")
        await cache.setValue("value6", forKey: "key6")
        
        // key2 should be evicted as it's least recently used
        let value2 = await cache.value(forKey: "key2")
        let value1 = await cache.value(forKey: "key1")
        XCTAssertNil(value2)
        XCTAssertNotNil(value1)
    }
}
