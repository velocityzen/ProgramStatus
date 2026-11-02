import Foundation

/// Everything that can go wrong while encoding, sending, or detecting status reports.
public enum ProgramStatusError: LocalizedError, Sendable, Equatable {
    case invalidID(String)
    case invalidApp(String)
    case invalidProgress(Int)
    case controlCharacter(TextField)
    case textTooLong(TextField, bytes: Int, limit: Int)
    case noTerminal
    case writeFailed(String)
    case invalidReply

    /// The free-text fields, which carry base64 of UTF-8 text.
    public enum TextField: String, Sendable {
        case title
        case message
    }

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
