import FP

/// Renders reports and the feature detection query as OSC 7501 sequences.
public enum StatusEncoder {
    /// `ESC ] 7501 ;`
    static let introducer = "\u{1B}]7501;"

    /// Encodes a report as one sequence, failing on the first invalid value.
    ///
    /// Valid values always fit the 4096-byte sequence cap, so there is no
    /// separate length check.
    public static func encode(
        _ report: StatusReport,
        terminator: Terminator = .st
    ) -> Result<String, ProgramStatusError> {
        Field.fields(of: report)
            .traverse { $0.encoded() }
            .map { $0.joined(separator: ":") }
            .map { frame($0, terminator: terminator) }
    }

    /// The feature detection query, `OSC 7501 ; ? ST`. Read the reply with
    /// ``Capabilities/parse(_:)``.
    public static func query(terminator: Terminator = .st) -> String {
        frame("?", terminator: terminator)
    }

    static func frame(_ body: String, terminator: Terminator) -> String {
        introducer + body + terminator.sequence
    }
}
