import Foundation

/// Where a sequence is written.
public enum Destination: Sendable {
    /// The controlling terminal (`/dev/tty`), so reports reach the user even
    /// when stdout and stderr are redirected.
    case terminal
    /// Standard output, but only while it is a terminal.
    case standardOutput
    /// Standard error, but only while it is a terminal.
    case standardError
    /// Any file handle, written as-is with no terminal check.
    case fileHandle(FileHandle)
}
