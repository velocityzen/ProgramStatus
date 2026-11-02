extension StatusReport {
    /// The `state` of a report. `kind` and `progress` live on the states that
    /// accept them, so a report cannot carry them anywhere else.
    public enum State: Sendable, Equatable {
        /// At rest, waiting for the user's next instruction.
        case idle
        /// Running. `progress` is a percentage, `nil` when indeterminate.
        case working(progress: Int? = nil)
        /// Finished a piece of work; the result is ready to look at.
        case done
        /// Cannot continue until the user does something. `kind` says what.
        case blocked(kind: BlockedKind? = nil, progress: Int? = nil)
        /// Failed and stopped.
        case error
        /// Not a state: removes the addressed record and every record beneath it.
        /// With no id, removes every record on the terminal.
        case clear
    }
}

extension StatusReport.State {
    /// The protocol's `state` value.
    public var name: String {
        switch self {
            case .idle: "idle"
            case .working: "working"
            case .done: "done"
            case .blocked: "blocked"
            case .error: "error"
            case .clear: "clear"
        }
    }

    var kind: StatusReport.BlockedKind? {
        guard case .blocked(let kind, _) = self else { return nil }
        return kind
    }

    var progress: Int? {
        switch self {
            case .working(let progress), .blocked(_, let progress): progress
            default: nil
        }
    }
}
