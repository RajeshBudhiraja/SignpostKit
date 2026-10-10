import os

/// Measures code as signpost intervals you can inspect in Instruments.
public struct Signpost {
    let signposter: OSSignposter

    /// Creates a signpost for a subsystem (usually your bundle ID) and category.
    public init(subsystem: String, category: String) {
        signposter = OSSignposter(subsystem: subsystem, category: category)
    }

    /// Measures synchronous work and returns its result.
    public func measure<T>(_ name: StaticString, _ work: () throws -> T) rethrows -> T {
        // Unique ID keeps overlapping intervals with the same name separate.
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval(name, id: id)
        // Ends the interval even if `work` throws.
        defer { signposter.endInterval(name, state) }
        return try work()
    }

    /// Measures asynchronous work and returns its result.
    public func measure<T>(_ name: StaticString, _ work: () async throws -> T) async rethrows -> T {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval(name, id: id)
        defer { signposter.endInterval(name, state) }
        return try await work()
    }
}
