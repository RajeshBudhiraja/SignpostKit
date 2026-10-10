import os

/// A running interval. End it exactly once; the compiler rejects a second `end()`.
public struct SignpostInterval: ~Copyable, Sendable {
    let signposter: OSSignposter
    let name: StaticString
    let state: OSSignpostIntervalState

    /// Ends the interval, optionally attaching metadata such as a result count.
    public consuming func end(_ metadata: @autoclosure () -> String? = nil, privacy: SignpostPrivacy = .public) {
        guard signposter.isEnabled, let metadata = metadata() else {
            signposter.endInterval(name, state)
            return
        }
        // OSLogMessage can't be forwarded, so each privacy level needs its own literal.
        switch privacy {
        case .public: signposter.endInterval(name, state, "\(metadata, privacy: .public)")
        case .private: signposter.endInterval(name, state, "\(metadata, privacy: .private)")
        }
    }
}
