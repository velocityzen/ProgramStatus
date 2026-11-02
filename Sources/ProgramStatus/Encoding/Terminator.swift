/// The string terminator that closes a sequence.
public enum Terminator: Sendable {
    /// `ESC \`, the standard string terminator.
    case st
    /// `BEL`, for terminals that only understand the older form.
    case bel

    var sequence: String {
        switch self {
            case .st: "\u{1B}\\"
            case .bel: "\u{07}"
        }
    }
}
