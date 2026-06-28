//
//  SwiftyCache.swift
//  SwiftyCache
//
//  Version 1.0.2
//
//  Created by CodingIran on 2025/4/10.
//

import Foundation
import OrderedCollections

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.10)
    #error("SwiftyCache doesn't support Swift versions below 5.10")
#endif

public final actor SwiftyCache<Key, Value>: Sendable where Key: Hashable & Sendable, Value: Sendable {
    /// The name of the cache.
    public private(set) var name: String

    /// The current total cost of values in the cache
    public private(set) var totalCost: Int = 0

    /// The maximum total cost that the cache can hold before it starts evicting objects.
    public private(set) var totalCostLimit: Int

    /// The maximum number of objects the cache should hold.
    public private(set) var countLimit: Int

    /// Whether to clear the cache when memory pressure is detected
    public private(set) var clearOnMemoryPressure: Bool

    /// The storage for the cache
    private var storage: OrderedDictionary<Key, Entry> = [:]

    /// The memory pressure source
    private let memoryPressureSource: SendableDispatchMemoryPressureSource

    /// Initialize the cache with the specified `totalCostLimit` and `countLimit`
    /// - Parameters:
    ///   - name: A descriptive name for the cache.
    ///   - totalCostLimit: The maximum total cost that the cache can hold before it starts evicting objects.
    ///   - countLimit: The maximum number of objects the cache should hold.
    ///   - clearOnMemoryPressure: Whether to clear the cache when memory pressure is detected
    public init(name: String = "",
                totalCostLimit: Int = .max,
                countLimit: Int = .max,
                clearOnMemoryPressure: Bool = true)
    {
        self.name = name
        self.totalCostLimit = Self.normalizedNonNegative(totalCostLimit)
        self.countLimit = Self.normalizedNonNegative(countLimit)
        self.clearOnMemoryPressure = clearOnMemoryPressure
        memoryPressureSource = .init(eventMask: [.warning, .critical])
        memoryPressureSource.setEventHandler { [weak self] in
            Task { [weak self] in
                guard let self, await self.clearOnMemoryPressure else { return }
                await self.removeAllValues()
            }
        }
        memoryPressureSource.activate()
    }

    deinit {
        memoryPressureSource.cancel()
    }
}

// MARK: - Public API

public extension SwiftyCache {
    /// The number of values currently stored in the cache
    var count: Int { storage.count }

    /// Whether the cache is empty
    var isEmpty: Bool { storage.isEmpty }

    /// Whether the cache is not empty
    var isNotEmpty: Bool { !isEmpty }

    /// Returns all keys in the cache from oldest to newest
    var allKeys: [Key] { Array(storage.keys) }

    /// Returns all values in the cache from oldest to newest
    var allValues: [Value] { storage.values.map(\.value) }

    /// Insert a value into the cache with optional `cost`
    /// - Parameters:
    ///   - value: The object to be stored in the cache.
    ///   - key: The key with which to associate the value.
    ///   - cost: The cost with which to associate the key-value pair.
    func setValue(_ value: Value?, forKey key: Key, cost: Int = 0) {
        guard let value else {
            removeValue(forKey: key)
            return
        }

        let normalizedCost = Self.normalizedNonNegative(cost)

        if let existing = storage.removeValue(forKey: key) {
            totalCost -= existing.cost
        }

        storage[key] = Entry(value: value, cost: normalizedCost)
        totalCost += normalizedCost

        trimIfNeeded()
    }

    /// Removes the value of the specified key in the cache.
    /// - Parameter key: The key identifying the value to be removed.
    /// - Returns: The value that was removed, or nil if no value is associated with key.
    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        guard let removed = storage.removeValue(forKey: key) else {
            return nil
        }
        totalCost -= removed.cost
        return removed.value
    }

    /// Returns the value associated with a given key.
    /// - Parameter key: A key identifying the value.
    /// - Returns: The value associated with key, or nil if no value is associated with key.
    func value(forKey key: Key) -> Value? {
        guard let entry = storage.removeValue(forKey: key) else {
            return nil
        }
        // Move to the end (most recently used)
        storage[key] = entry
        return entry.value
    }

    /// Empties the cache.
    func removeAllValues() {
        storage.removeAll()
        totalCost = 0
    }

    /// Updates the cache name.
    /// - Parameter name: A descriptive name for the cache.
    func setName(_ name: String) {
        self.name = name
    }

    /// Updates the total cost limit and trims existing values if needed.
    /// - Parameter limit: The new total cost limit. Negative values are normalized to zero.
    func setTotalCostLimit(_ limit: Int) {
        totalCostLimit = Self.normalizedNonNegative(limit)
        trimIfNeeded()
    }

    /// Updates the count limit and trims existing values if needed.
    /// - Parameter limit: The new count limit. Negative values are normalized to zero.
    func setCountLimit(_ limit: Int) {
        countLimit = Self.normalizedNonNegative(limit)
        trimIfNeeded()
    }

    /// Updates whether memory-pressure events should clear the cache.
    /// - Parameter clearOnMemoryPressure: Whether memory-pressure events should clear all values.
    func setClearOnMemoryPressure(_ clearOnMemoryPressure: Bool) {
        self.clearOnMemoryPressure = clearOnMemoryPressure
    }
}

// MARK: - Private

private extension SwiftyCache {
    struct Entry: Sendable {
        let value: Value
        let cost: Int

        init(value: Value, cost: Int) {
            self.value = value
            self.cost = cost
        }
    }

    func trimIfNeeded() {
        while !storage.isEmpty, (totalCost > totalCostLimit || count > countLimit) {
            let (_, entry) = storage.removeFirst()
            totalCost -= entry.cost
        }
    }

    static func normalizedNonNegative(_ value: Int) -> Int {
        max(0, value)
    }
}

// MARK: - Make `DispatchSourceMemoryPressure` Sendable

private final class SendableDispatchMemoryPressureSource: @unchecked Sendable {
    typealias DispatchSourceHandler = @Sendable @convention(block) () -> Void

    let source: DispatchSourceMemoryPressure

    init(eventMask: DispatchSource.MemoryPressureEvent, queue: DispatchQueue? = nil) {
        source = DispatchSource.makeMemoryPressureSource(eventMask: eventMask, queue: queue)
    }

    func activate() { source.activate() }

    func cancel() { source.cancel() }

    func setEventHandler(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], handler: SendableDispatchMemoryPressureSource.DispatchSourceHandler?) {
        source.setEventHandler(qos: qos, flags: flags) {
            handler?()
        }
    }
}
