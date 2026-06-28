@testable import SwiftyCache
import Testing

@Suite("SwiftyCache")
struct SwiftyCacheTests {
    @Test("initializer stores name and normalizes limits")
    func initializerStoresNameAndNormalizesLimits() async {
        let cache = SwiftyCache<String, String>(
            name: "avatars",
            totalCostLimit: -10,
            countLimit: -5,
            clearOnMemoryPressure: false
        )

        #expect(await cache.name == "avatars")
        #expect(await cache.totalCostLimit == 0)
        #expect(await cache.countLimit == 0)
        #expect(await cache.clearOnMemoryPressure == false)
    }

    @Test("stores and returns values")
    func storesAndReturnsValues() async {
        let cache = SwiftyCache<String, String>()

        await cache.setValue("value1", forKey: "key1")

        #expect(await cache.value(forKey: "key1") == "value1")
    }

    @Test("setting nil removes the value and cost")
    func settingNilRemovesValueAndCost() async {
        let cache = SwiftyCache<String, String>()

        await cache.setValue("value1", forKey: "key1", cost: 25)
        await cache.setValue(nil, forKey: "key1")

        #expect(await cache.value(forKey: "key1") == nil)
        #expect(await cache.totalCost == 0)
        #expect(await cache.isEmpty)
    }

    @Test("removeValue returns removed value and updates state")
    func removeValueReturnsRemovedValueAndUpdatesState() async {
        let cache = SwiftyCache<String, String>()

        await cache.setValue("value1", forKey: "key1", cost: 30)
        let removed = await cache.removeValue(forKey: "key1")

        #expect(removed == "value1")
        #expect(await cache.value(forKey: "key1") == nil)
        #expect(await cache.totalCost == 0)
    }

    @Test("removeValue for missing key returns nil and keeps state")
    func removeValueForMissingKeyReturnsNilAndKeepsState() async {
        let cache = SwiftyCache<String, String>()

        let removed = await cache.removeValue(forKey: "missing")

        #expect(removed == nil)
        #expect(await cache.isEmpty)
        #expect(await cache.totalCost == 0)
    }

    @Test("setting nil for missing key keeps cache empty")
    func settingNilForMissingKeyKeepsCacheEmpty() async {
        let cache = SwiftyCache<String, String>()

        await cache.setValue(nil, forKey: "missing")

        #expect(await cache.isEmpty)
        #expect(await cache.totalCost == 0)
    }

    @Test("removeAllValues clears values and cost")
    func removeAllValuesClearsValuesAndCost() async {
        let cache = SwiftyCache<String, String>()

        await cache.setValue("value1", forKey: "key1", cost: 10)
        await cache.setValue("value2", forKey: "key2", cost: 20)
        await cache.removeAllValues()

        #expect(await cache.isEmpty)
        #expect(await cache.count == 0)
        #expect(await cache.totalCost == 0)
    }

    @Test("count and emptiness properties reflect contents")
    func countAndEmptinessReflectContents() async {
        let cache = SwiftyCache<String, String>()

        #expect(await cache.isEmpty)
        #expect(await cache.isNotEmpty == false)

        await cache.setValue("value1", forKey: "key1")

        #expect(await cache.count == 1)
        #expect(await cache.isEmpty == false)
        #expect(await cache.isNotEmpty)
    }

    @Test("allKeys and allValues preserve oldest to newest order")
    func allKeysAndValuesPreserveOrder() async {
        let cache = SwiftyCache<String, String>()

        await cache.setValue("value1", forKey: "key1")
        await cache.setValue("value2", forKey: "key2")

        #expect(await cache.allKeys == ["key1", "key2"])
        #expect(await cache.allValues == ["value1", "value2"])
    }

    @Test("count limit evicts oldest values")
    func countLimitEvictsOldestValues() async {
        let cache = SwiftyCache<String, String>(countLimit: 2)

        await cache.setValue("value1", forKey: "key1")
        await cache.setValue("value2", forKey: "key2")
        await cache.setValue("value3", forKey: "key3")

        #expect(await cache.allKeys == ["key2", "key3"])
        #expect(await cache.value(forKey: "key1") == nil)
    }

    @Test("total cost limit evicts oldest values until under limit")
    func totalCostLimitEvictsOldestValuesUntilUnderLimit() async {
        let cache = SwiftyCache<String, String>(totalCostLimit: 100)

        await cache.setValue("value1", forKey: "key1", cost: 60)
        await cache.setValue("value2", forKey: "key2", cost: 50)
        await cache.setValue("value3", forKey: "key3", cost: 20)

        #expect(await cache.allKeys == ["key2", "key3"])
        #expect(await cache.totalCost == 70)
    }

    @Test("value access moves key to most recently used position")
    func valueAccessMovesKeyToMostRecentlyUsedPosition() async {
        let cache = SwiftyCache<String, String>(countLimit: 2)

        await cache.setValue("value1", forKey: "key1")
        await cache.setValue("value2", forKey: "key2")
        _ = await cache.value(forKey: "key1")
        await cache.setValue("value3", forKey: "key3")

        #expect(await cache.allKeys == ["key1", "key3"])
        #expect(await cache.value(forKey: "key2") == nil)
    }

    @Test("updating an existing key replaces cost and refreshes recency")
    func updatingExistingKeyReplacesCostAndRefreshesRecency() async {
        let cache = SwiftyCache<String, String>(countLimit: 2)

        await cache.setValue("value1", forKey: "key1", cost: 40)
        await cache.setValue("value2", forKey: "key2", cost: 20)
        await cache.setValue("updated", forKey: "key1", cost: 15)
        await cache.setValue("value3", forKey: "key3")

        #expect(await cache.allKeys == ["key1", "key3"])
        #expect(await cache.value(forKey: "key1") == "updated")
        #expect(await cache.totalCost == 15)
    }

    @Test("zero count limit keeps cache empty")
    func zeroCountLimitKeepsCacheEmpty() async {
        let cache = SwiftyCache<String, String>(countLimit: 0)

        await cache.setValue("value1", forKey: "key1")

        #expect(await cache.isEmpty)
        #expect(await cache.totalCost == 0)
    }

    @Test("zero total cost limit evicts positive cost values")
    func zeroTotalCostLimitEvictsPositiveCostValues() async {
        let cache = SwiftyCache<String, String>(totalCostLimit: 0)

        await cache.setValue("value1", forKey: "key1", cost: 1)
        await cache.setValue("value2", forKey: "key2", cost: 0)

        #expect(await cache.allKeys == ["key2"])
        #expect(await cache.totalCost == 0)
    }

    @Test("negative count limit is normalized to zero capacity")
    func negativeCountLimitIsNormalizedToZeroCapacity() async {
        let cache = SwiftyCache<String, String>(countLimit: -1)

        await cache.setValue("value1", forKey: "key1")

        #expect(await cache.countLimit == 0)
        #expect(await cache.isEmpty)
    }

    @Test("negative total cost limit is normalized to zero")
    func negativeTotalCostLimitIsNormalizedToZero() async {
        let cache = SwiftyCache<String, String>(totalCostLimit: -1)

        await cache.setValue("value1", forKey: "key1", cost: 1)

        #expect(await cache.totalCostLimit == 0)
        #expect(await cache.isEmpty)
    }

    @Test("negative item cost is normalized to zero")
    func negativeItemCostIsNormalizedToZero() async {
        let cache = SwiftyCache<String, String>(totalCostLimit: 0)

        await cache.setValue("value1", forKey: "key1", cost: -10)

        #expect(await cache.value(forKey: "key1") == "value1")
        #expect(await cache.totalCost == 0)
    }

    @Test("setCountLimit trims existing values")
    func setCountLimitTrimsExistingValues() async {
        let cache = SwiftyCache<String, String>()

        await cache.setValue("value1", forKey: "key1")
        await cache.setValue("value2", forKey: "key2")
        await cache.setValue("value3", forKey: "key3")
        await cache.setCountLimit(2)

        #expect(await cache.countLimit == 2)
        #expect(await cache.allKeys == ["key2", "key3"])
    }

    @Test("setTotalCostLimit trims existing values")
    func setTotalCostLimitTrimsExistingValues() async {
        let cache = SwiftyCache<String, String>()

        await cache.setValue("value1", forKey: "key1", cost: 50)
        await cache.setValue("value2", forKey: "key2", cost: 40)
        await cache.setValue("value3", forKey: "key3", cost: 30)
        await cache.setTotalCostLimit(70)

        #expect(await cache.totalCostLimit == 70)
        #expect(await cache.allKeys == ["key2", "key3"])
        #expect(await cache.totalCost == 70)
    }

    @Test("runtime limits normalize negative values")
    func runtimeLimitsNormalizeNegativeValues() async {
        let cache = SwiftyCache<String, String>()

        await cache.setValue("value1", forKey: "key1")
        await cache.setCountLimit(-1)
        await cache.setTotalCostLimit(-1)

        #expect(await cache.countLimit == 0)
        #expect(await cache.totalCostLimit == 0)
        #expect(await cache.isEmpty)
    }

    @Test("setName updates cache name")
    func setNameUpdatesCacheName() async {
        let cache = SwiftyCache<String, String>()

        await cache.setName("avatars")

        #expect(await cache.name == "avatars")
    }

    @Test("setClearOnMemoryPressure can be toggled repeatedly")
    func setClearOnMemoryPressureCanBeToggledRepeatedly() async {
        let cache = SwiftyCache<String, String>(clearOnMemoryPressure: true)

        await cache.setClearOnMemoryPressure(true)
        await cache.setClearOnMemoryPressure(false)
        await cache.setClearOnMemoryPressure(false)
        await cache.setClearOnMemoryPressure(true)
        await cache.setClearOnMemoryPressure(true)

        #expect(await cache.clearOnMemoryPressure)
    }
}
