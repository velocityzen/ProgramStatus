extension StatusReport {
    /// At rest, waiting for the user's next instruction. Report this when the
    /// user interrupts or cancels the program, too.
    public static func idle(
        _ message: String? = nil,
        app: String? = nil,
        id: String? = nil,
        title: String? = nil
    ) -> StatusReport {
        StatusReport(state: .idle, id: id, app: app, title: title, message: message)
    }

    /// Running, with an optional 0–100 `progress`.
    public static func working(
        _ message: String? = nil,
        progress: Int? = nil,
        app: String? = nil,
        id: String? = nil,
        title: String? = nil
    ) -> StatusReport {
        StatusReport(
            state: .working(progress: progress),
            id: id,
            app: app,
            title: title,
            message: message
        )
    }

    /// Finished. Send it right before exiting so the user finds a record behind.
    public static func done(
        _ message: String? = nil,
        app: String? = nil,
        id: String? = nil,
        title: String? = nil
    ) -> StatusReport {
        StatusReport(state: .done, id: id, app: app, title: title, message: message)
    }

    /// Waiting on the user; `kind` says for what, `message` says why.
    public static func blocked(
        _ message: String? = nil,
        kind: BlockedKind? = nil,
        progress: Int? = nil,
        app: String? = nil,
        id: String? = nil,
        title: String? = nil
    ) -> StatusReport {
        StatusReport(
            state: .blocked(kind: kind, progress: progress),
            id: id,
            app: app,
            title: title,
            message: message
        )
    }

    /// Failed and stopped. Send it right before exiting so the user finds a record behind.
    public static func error(
        _ message: String? = nil,
        app: String? = nil,
        id: String? = nil,
        title: String? = nil
    ) -> StatusReport {
        StatusReport(state: .error, id: id, app: app, title: title, message: message)
    }

    /// Removes the record at `id` and everything beneath it; with no id, every record.
    public static func clear(id: String? = nil) -> StatusReport {
        StatusReport(state: .clear, id: id)
    }
}
