extension StatusReport {
    /// The report with `app` set to `fallback` when it has none of its own.
    /// `clear` reports stay as they are: clear reads nothing but `id`.
    func inheriting(app fallback: String?) -> StatusReport {
        guard app == nil, state != .clear else { return self }
        return StatusReport(state: state, id: id, app: fallback, title: title, message: message)
    }
}
