import Foundation
import os

/// Measures code as signpost intervals and events you can inspect in Instruments.
public struct Signpost: Sendable {
    /// The underlying signposter, for APIs SignpostKit doesn't wrap.
    public let signposter: OSSignposter

    /// Creates a signpost for a subsystem (usually your bundle ID) and category.
    public init(subsystem: String = Signpost.defaultSubsystem, category: String) {
        signposter = OSSignposter(subsystem: subsystem, category: category)
    }

    /// Creates a signpost that shares its subsystem and category with a `Logger`.
    public init(logger: Logger) {
        signposter = OSSignposter(logger: logger)
    }

    init(signposter: OSSignposter) {
        self.signposter = signposter
    }

    /// Signposts shown in Instruments' dedicated Points of Interest track.
    public static func pointsOfInterest(subsystem: String = Signpost.defaultSubsystem) -> Signpost {
        Signpost(signposter: OSSignposter(subsystem: subsystem, category: .pointsOfInterest))
    }

    /// A signpost that records nothing. Swap it in to turn signposts off.
    public static let disabled = Signpost(signposter: .disabled)

    /// The app's bundle ID, or "SignpostKit" when there is none (for example in command-line tools).
    public static var defaultSubsystem: String { Bundle.main.bundleIdentifier ?? "SignpostKit" }

    /// `false` for `.disabled`. Metadata closures are skipped when this is `false`.
    public var isEnabled: Bool { signposter.isEnabled }

    // MARK: - Intervals

    /// Begins an interval to end later, possibly in another function.
    public func begin(
        _ name: StaticString,
        id: SignpostID = .unique,
        _ metadata: @autoclosure () -> String? = nil,
        privacy: SignpostPrivacy = .public
    ) -> SignpostInterval {
        let state = beginState(name, id: id, metadata(), privacy: privacy)
        return SignpostInterval(signposter: signposter, name: name, state: state)
    }

    /// Begins an animation interval. Instruments' hitch analysis uses these to attribute dropped frames.
    public func beginAnimation(
        _ name: StaticString,
        id: SignpostID = .unique,
        _ metadata: @autoclosure () -> String? = nil,
        privacy: SignpostPrivacy = .public
    ) -> SignpostInterval {
        let signpostID = id.resolve(with: signposter)
        let state: OSSignpostIntervalState
        if isEnabled, let metadata = metadata() {
            switch privacy {
            case .public: state = signposter.beginAnimationInterval(name, id: signpostID, "\(metadata, privacy: .public)")
            case .private: state = signposter.beginAnimationInterval(name, id: signpostID, "\(metadata, privacy: .private)")
            }
        } else {
            state = signposter.beginAnimationInterval(name, id: signpostID)
        }
        return SignpostInterval(signposter: signposter, name: name, state: state)
    }

    /// Measures synchronous work and returns its result.
    public func measure<T>(
        _ name: StaticString,
        id: SignpostID = .unique,
        _ metadata: @autoclosure () -> String? = nil,
        privacy: SignpostPrivacy = .public,
        _ work: () throws -> T
    ) rethrows -> T {
        let state = beginState(name, id: id, metadata(), privacy: privacy)
        // Ends the interval even if `work` throws.
        defer { signposter.endInterval(name, state) }
        return try work()
    }

    /// Measures asynchronous work and returns its result.
    public func measure<T>(
        _ name: StaticString,
        id: SignpostID = .unique,
        _ metadata: @autoclosure () -> String? = nil,
        privacy: SignpostPrivacy = .public,
        _ work: () async throws -> T
    ) async rethrows -> T {
        let state = beginState(name, id: id, metadata(), privacy: privacy)
        defer { signposter.endInterval(name, state) }
        return try await work()
    }

    private func beginState(
        _ name: StaticString,
        id: SignpostID,
        _ metadata: @autoclosure () -> String?,
        privacy: SignpostPrivacy
    ) -> OSSignpostIntervalState {
        let signpostID = id.resolve(with: signposter)
        guard isEnabled, let metadata = metadata() else {
            return signposter.beginInterval(name, id: signpostID)
        }
        // OSLogMessage can't be forwarded, so each privacy level needs its own literal.
        switch privacy {
        case .public: return signposter.beginInterval(name, id: signpostID, "\(metadata, privacy: .public)")
        case .private: return signposter.beginInterval(name, id: signpostID, "\(metadata, privacy: .private)")
        }
    }

    // MARK: - Events

    /// Marks a single moment, such as a cache miss or a retry.
    public func event(
        _ name: StaticString,
        id: SignpostID = .exclusive,
        _ metadata: @autoclosure () -> String? = nil,
        privacy: SignpostPrivacy = .public
    ) {
        let signpostID = id.resolve(with: signposter)
        guard isEnabled, let metadata = metadata() else {
            signposter.emitEvent(name, id: signpostID)
            return
        }
        switch privacy {
        case .public: signposter.emitEvent(name, id: signpostID, "\(metadata, privacy: .public)")
        case .private: signposter.emitEvent(name, id: signpostID, "\(metadata, privacy: .private)")
        }
    }
}
