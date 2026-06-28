# Repository Guidelines

## Project Structure & Module Organization

SwiftyCache is a Swift Package Manager library. The main manifest is `Package.swift` for Swift 6, with `Package@swift-5.10.swift` kept for Swift 5.10 compatibility. Library source lives in `Sources/SwiftyCache/SwiftyCache.swift`; keep public API changes in this target. Privacy resources live under `Sources/SwiftyCache/Resources/`, currently `PrivacyInfo.xcprivacy`. Tests live in `Tests/SwiftyCacheTests/SwiftyCacheTests.swift` and should mirror cache behavior: insertion, eviction, cost limits, memory-pressure behavior, and concurrency-sensitive access.

## Build, Test, and Development Commands

- `swift package resolve` updates package dependencies from `Package.resolved`.
- `swift build` compiles the library target against the default manifest.
- `swift test` runs the XCTest suite.
- `swift test --enable-code-coverage` runs tests with coverage data when local tooling supports it.

Run commands from the repository root. Do not edit `Package.resolved` unless dependency versions intentionally change.

## Coding Style & Naming Conventions

Use standard Swift style with 4-space indentation and braces on the declaration line, matching the existing code. Prefer explicit access control for public API and keep implementation details in `private extension` blocks. Public types, actors, and structs use `UpperCamelCase`; methods, properties, variables, and test helpers use `lowerCamelCase`. Keep actor-isolated API async-safe and preserve `Sendable` constraints unless a change explicitly justifies relaxing them.

## Testing Guidelines

The test framework is XCTest. Name tests with the `test...` prefix and describe the behavior under test, for example `testLRUBehavior` or `testSetNilRemovesValue`. Add or update tests for every behavior change, especially eviction order, cost accounting, count limits, and nil-removal semantics. For public API additions, include at least one positive-path test and one boundary or regression case.

## Commit & Pull Request Guidelines

Recent history uses short, descriptive commit subjects such as `Update README.md`, `fix typo`, and release commits like `Release 1.0.1`. Keep commits focused on one logical change. Pull requests should include a concise summary, test results such as `swift test`, linked issues when applicable, and README updates for user-facing API changes. Mention platform or privacy-resource changes explicitly.

## Agent-Specific Instructions

Keep changes narrow. Preserve the Swift 5.10 compatibility manifest when editing package settings, and verify both manifests if a dependency, platform, or language-mode change affects package resolution.
