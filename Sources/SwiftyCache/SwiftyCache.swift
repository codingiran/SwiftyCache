//
//  SwiftyCache.swift
//  SwiftyCache
//
//  Version 1.0.0
//
//  Created by CodingIran on 2025/4/10.
//

import Foundation
import OrderedCollections

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.9)
#error("SwiftyCache doesn't support Swift versions below 5.9")
#endif

public final actor SwiftyCache<Key, Value>: Sendable where Key: Hashable & Sendable, Value: Sendable {
    /// The name of the cache.
    public var name: String = ""

    /// The current total cost of values in the cache
    public private(set) var totalCost: Int = 0

    /// The maximum total cost that the cache can hold before it starts evicting objects.
    public var totalCostLimit: Int {
        didSet { trimIfNeeded() }
    }

    /// The maximum number of objects the cache should hold.
    public var countLimit: Int {
        didSet { trimIfNeeded() }
    }

    /// Whether to clear the cache when memory pressure is detected
    public var clearOnMemoryPressure: Bool {
        didSet { triggerMemoryPressure() }
    }

    /// The storage for the cache
    private var storage: OrderedDictionary<Key, Entry> = [:]

    /// The memory pressure source
    private let memoryPressureSource: SendableDispatchMemoryPressureSource

    /// Initialize the cache with the specified `totalCostLimit` and `countLimit`
    /// - Parameters:
    ///   - totalCostLimit: The maximum total cost that the cache can hold before it starts evicting objects.
    ///   - countLimit: The maximum number of objects the cache should hold.
    ///   - clearOnMemoryPressure: Whether to clear the cache when memory pressure is detected
    public init(totalCostLimit: Int, countLimit: Int, clearOnMemoryPressure: Bool = true) {
        self.totalCostLimit = totalCostLimit
        self.countLimit = countLimit
        self.clearOnMemoryPressure = clearOnMemoryPressure
        self.memoryPressureSource = .init(eventMask: [.warning, .critical])
        memoryPressureSource.setEventHandler { [weak self] in
            guard let self else { return }
            Task {
                guard await self.clearOnMemoryPressure else { return }
                await self.removeAllValues()
            }
        }
        memoryPressureSource.activate()
        if !clearOnMemoryPressure {
            memoryPressureSource.suspend()
        }
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
    ///   - g: The cost with which to associate the key-value pair.
    func setValue(_ value: Value?, forKey key: Key, cost g: Int = 0) {
        guard let value else {
            removeValue(forKey: key)
            return
        }

        if let existing = storage.removeValue(forKey: key) {
            totalCost -= existing.cost
        }

        storage[key] = Entry(value: value, cost: g)
        totalCost += g

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
    /// - Parameter key: An key identifying the value.
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
        while totalCost > totalCostLimit || count > countLimit {
            let (_, entry) = storage.removeFirst()
            totalCost -= entry.cost
        }
    }
}

// MARK: - Memory Pressure

private extension SwiftyCache {
    func triggerMemoryPressure() {
        if clearOnMemoryPressure {
            memoryPressureSource.resume()
        } else {
            memoryPressureSource.suspend()
        }
    }
}

// MARK: - Make `DispatchSourceMemoryPressure` Sendable

private final class SendableDispatchMemoryPressureSource: @unchecked Sendable {
    typealias DispatchSourceHandler = @Sendable @convention(block) () -> Void

    let source: DispatchSourceMemoryPressure

    init(eventMask: DispatchSource.MemoryPressureEvent, queue: DispatchQueue? = nil) {
        self.source = DispatchSource.makeMemoryPressureSource(eventMask: eventMask, queue: queue)
    }

    func activate() { source.activate() }

    func cancel() { source.cancel() }

    func resume() { source.resume() }

    func suspend() { source.suspend() }

    var isCancelled: Bool { source.isCancelled }

    func setEventHandler(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], handler: SendableDispatchMemoryPressureSource.DispatchSourceHandler?) {
        source.setEventHandler(qos: qos, flags: flags) {
            handler?()
        }
    }
}
