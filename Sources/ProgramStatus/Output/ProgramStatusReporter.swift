/// Sends reports for one program: fills in its `app`, encodes, and writes.
///
/// ```swift
/// let status = ProgramStatusReporter(app: "photos")
/// status.send(.working("Syncing photos"))
/// status.send(.done("Photos synced"))
/// ```
public struct ProgramStatusReporter: Sendable {
    /// Added to every report that has no `app` of its own.
    public let app: String?
    /// Where encoded reports are written.
    public let destination: Destination
    /// What closes each sequence.
    public let terminator: Terminator

    /// A reporter that writes to the controlling terminal and ends each
    /// sequence with ST, unless told otherwise.
    public init(
        app: String? = nil,
        destination: Destination = .terminal,
        terminator: Terminator = .st
    ) {
        self.app = app
        self.destination = destination
        self.terminator = terminator
    }

    /// Encodes and writes one report.
    ///
    /// Status reporting is best-effort, so the result is discardable; check it
    /// when a failure matters, e.g. an invalid id in tests.
    @discardableResult
    public func send(_ report: StatusReport) -> Result<Void, ProgramStatusError> {
        StatusEncoder.encode(report.inheriting(app: app), terminator: terminator)
            .flatMap(destination.write)
    }
}
