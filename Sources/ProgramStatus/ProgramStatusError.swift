import Foundation

/// Everything that can go wrong while encoding, sending, or detecting status reports.
public enum ProgramStatusError: LocalizedError, Sendable, Equatable {
    /// An id outside the grammar: segments of `[A-Za-z0-9_.+-]{1,32}` joined
    /// by `/`, at most 8 levels and 128 bytes.
    case invalidID(String)
    /// An `app` outside `[A-Za-z0-9_.+-]{1,32}`.
    case invalidApp(String)
    /// A progress outside 0–100.
    case invalidProgress(Int)
    /// A title or message with a control character, such as a newline.
    case controlCharacter(TextField)
    /// A title or message over its UTF-8 byte limit: 192 for the title, 2048
    /// for the message.
    case textTooLong(TextField, bytes: Int, limit: Int)
    /// No terminal to write to: the process has no controlling terminal, or
    /// standard output or standard error is not a TTY.
    case noTerminal
    /// The write itself failed; carries the underlying error's description.
    case writeFailed(String)
    /// The text holds no feature detection reply.
    case invalidReply

    /// The free-text fields, which carry base64 of UTF-8 text.
    public enum TextField: String, Sendable {
        /// The record's `title`.
        case title
        /// The record's `msg`.
        case message
    }

    /// A message that says what was wrong and what the specification allows.
    public var errorDescription: String? {
        switch self {
            case .invalidID(let id):
                "Invalid record id \"\(id)\": use up to 8 segments of [A-Za-z0-9_.+-]{1,32} joined by /, at most 128 bytes."
            case .invalidApp(let app):
                "Invalid app \"\(app)\": use 1 to 32 characters of [A-Za-z0-9_.+-]."
            case .invalidProgress(let value):
                "Invalid progress \(value): use an integer from 0 to 100."
            case .controlCharacter(let field):
                "The \(field.rawValue) contains a control character; it must be a single line."
            case .textTooLong(let field, let bytes, let limit):
                "The \(field.rawValue) is \(bytes) bytes of UTF-8; the limit is \(limit)."
            case .noTerminal:
                "There is no terminal to report to."
            case .writeFailed(let reason):
                "Could not write the status report: \(reason)"
            case .invalidReply:
                "Not a Program Status Protocol feature detection reply."
        }
    }
}
