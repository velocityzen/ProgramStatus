/// What a terminal says it accepts, from its feature detection reply.
public struct Capabilities: Sendable, Equatable {
    /// Accepted `state` values, not counting `clear`.
    public let states: Set<String>
    /// Accepted `kind` values.
    public let kinds: Set<String>

    /// What a reply without `states` or `kinds` means. The specification fixes
    /// these lists; later revisions add states and kinds through the reply.
    public static let baseline = Capabilities(
        states: ["idle", "working", "done", "blocked", "error"],
        kinds: ["permission", "question", "auth"]
    )

    /// Capabilities from explicit lists; ``parse(_:)`` builds them from a reply.
    public init(states: Set<String>, kinds: Set<String>) {
        self.states = states
        self.kinds = kinds
    }

    /// Whether the terminal accepts the state. `clear` is not a state and is
    /// always accepted.
    public func supports(_ state: StatusReport.State) -> Bool {
        state == .clear || states.contains(state.name)
    }

    /// Whether the terminal accepts the blocked `kind`.
    public func supports(_ kind: StatusReport.BlockedKind) -> Bool {
        kinds.contains(kind.rawValue)
    }
}
