import os

/// How a signpost is identified, so Instruments can match each interval's begin and end.
public enum SignpostID {
    /// Only one interval with this name runs at a time. Overlapping intervals get mismatched.
    case exclusive
    /// A fresh ID for every interval. Safe for work that runs in parallel.
    case unique
    /// The same ID for the same object, so all signposts for one object line up together.
    case object(AnyObject)

    func resolve(with signposter: OSSignposter) -> OSSignpostID {
        switch self {
        case .exclusive: .exclusive
        case .unique: signposter.makeSignpostID()
        case .object(let object): signposter.makeSignpostID(from: object)
        }
    }
}

/// Whether metadata is visible in traces or redacted as `<private>`.
public enum SignpostPrivacy: Sendable {
    /// Always visible. Use for counts, file names, and screen names.
    case `public`
    /// Redacted where the system hides private data. Use for anything user-specific.
    case `private`
}
