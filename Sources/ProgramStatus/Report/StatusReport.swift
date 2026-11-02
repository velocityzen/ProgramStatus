/// One report: what a program tells the terminal about one record.
///
/// A report replaces its record completely — a key missing from the report
/// is missing from the record afterwards — so include `app` and `title` in
/// every report that should carry them.
public struct StatusReport: Sendable, Equatable {
    /// What the record is doing, with the `kind` and `progress` its state accepts.
    public let state: State
    /// Record path such as `build/test`; `nil` addresses the root record.
    public let id: String?
    /// Stable program identifier such as `cargo`. A record without one takes
    /// it from its nearest ancestor.
    public let app: String?
    /// Short human-readable label, for programs that report several records.
    public let title: String?
    /// One human-readable line: what the record is doing, waiting for, or finished.
    public let message: String?

    /// A report built field by field. The constructors such as
    /// ``working(_:progress:app:id:title:)`` read better at call sites.
    public init(
        state: State,
        id: String? = nil,
        app: String? = nil,
        title: String? = nil,
        message: String? = nil
    ) {
        self.state = state
        self.id = id
        self.app = app
        self.title = title
        self.message = message
    }
}

extension StatusReport {
    /// What a blocked program needs from the user.
    public enum BlockedKind: String, Sendable, CaseIterable {
        /// Approval to do something.
        case permission
        /// The user must type an answer.
        case question
        /// A login, token, or credential.
        case auth
    }
}
