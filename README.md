# 💾 SwiftyCache

[![Swift Package Manager](https://img.shields.io/badge/SPM-Compatible-orange.svg?style=flat)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)](#)
[![Contact](https://img.shields.io/badge/contact-codingiran%40gmail.com-blue.svg)](mailto:codingiran@gmail.com)

**SwiftyCache** is a lightweight, elegant, and performant in-memory cache written purely in Swift.  
It supports Least-Recently-Used (LRU) eviction logic using Swift Collections’ [`OrderedDictionary`](https://github.com/apple/swift-collections), with optional cost-based cleanup and memory warning handling for Apple platforms.

> Simple. Fast. Swifty.

---

## 🚀 Features

- ✅ LRU (Least-Recently-Used) eviction strategy
- ✅ Cost-based cleanup (`totalCostLimit`)
- ✅ Count-based cleanup (`countLimit`)
- ✅ `MemoryWarning` cleanup
- ✅ Thread-safe design ready
- ✅ No Objective-C / Foundation subclassing
- ✅ 100% Swift + SPM support
- ✅ Clean and minimal API

---

## 📦 Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/codingiran/SwiftyCache.git", from: "1.0.0")
]
```

Then import where needed:

```swift
import SwiftyCache
```

---

## 🧩 Usage

### Create a cache

```swift
let cache = SwiftyCache<String, Data>(
    totalCostLimit: 10_000,  // Optional
    countLimit: 100          // Optional
)
```

### Store & retrieve values

```swift
cache.setValue(imageData, forKey: "avatar", cost: imageData.count)

let cachedData = cache.value(forKey: "avatar")
```

### Eviction

- Least Recently Used items are automatically evicted when:
  - `countLimit` is exceeded
  - `totalCostLimit` is exceeded
  - Memory warning([DispatchSourceMemoryPressure](https://developer.apple.com/documentation/dispatch/dispatchsourcememorypressure)) is received

### Remove items

```swift
cache.removeValue(forKey: "avatar")
cache.removeAllValues()
```

---

## 🧪 LRU Example

```swift
let cache = SwiftyCache<String, Int>(countLimit: 3)

cache.setValue(1, forKey: "A")
cache.setValue(2, forKey: "B")
cache.setValue(3, forKey: "C")

_ = cache.value(forKey: "A") // A is now most recently used

cache.setValue(4, forKey: "D") // B is evicted (least recently used)

print(cache.allKeys) // ["C", "A", "D"]
```

---

## 🧱 Implementation Highlights

- Using Swift actor for thread safety
- Implements `NSCache`-like API for easy integration
- Built atop [`OrderedDictionary`](https://github.com/apple/swift-collections) to avoid managing doubly-linked list manually
- Reorders keys internally on access to preserve LRU order
- Minimal dependencies, cleanly integrated with `DispatchSourceMemoryPressure` for memory warnings

---

## 📁 Project Structure

```swift
SwiftyCache/
├── Sources/
│   └── SwiftyCache.swift
├── Package.swift
└── README.md ← You are here
```

---

## 📄 License

This project is licensed under the MIT License.  
See [LICENSE](./LICENSE) for more information.

---

## 🤝 Contributing

Pull requests are welcome!  
If you'd like to add a feature, fix a bug, or improve documentation:

- Fork the repo
- Create your feature branch: `git checkout -b feature/your-feature`
- Commit your changes: `git commit -m "Add some feature"`
- Push to the branch: `git push origin feature/your-feature`
- Open a Pull Request

---

## 📬 Contact

Feel free to reach out:

**📧 Email**: [codingiran@gmail.com](mailto:codingiran@gmail.com)  
**📦 GitHub**: [github.com/codingiran/SwiftyCache](https://github.com/codingiran/SwiftyCache.git)

---

> Made with ❤️ by @codingiran
