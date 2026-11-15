import Foundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#endif

extension Destination {
    /// Writes the sequence. Fails with ``ProgramStatusError/noTerminal`` when
    /// there is no terminal to write to — a log file or a pipe never gets
    /// escape sequences.
    public func write(_ sequence: String) -> Result<Void, ProgramStatusError> {
        switch self {
            case .terminal:
                Self.writeToTerminal(sequence)
            case .standardOutput:
                Self.requireTerminal(.standardOutput).flatMap { Self.write(sequence, to: $0) }
            case .standardError:
                Self.requireTerminal(.standardError).flatMap { Self.write(sequence, to: $0) }
            case .fileHandle(let handle):
                Self.write(sequence, to: handle)
        }
    }
}

extension Destination {
    /// Opens `/dev/tty` for one write and closes it afterwards. Opening fails
    /// when the process has no controlling terminal (CI, cron, daemons).
    static func writeToTerminal(_ sequence: String) -> Result<Void, ProgramStatusError> {
        guard let terminal = FileHandle(forWritingAtPath: "/dev/tty") else {
            return .failure(.noTerminal)
        }
        defer { try? terminal.close() }
        return write(sequence, to: terminal)
    }

    static func requireTerminal(_ handle: FileHandle) -> Result<FileHandle, ProgramStatusError> {
        isatty(handle.fileDescriptor) == 1 ? .success(handle) : .failure(.noTerminal)
    }

    static func write(
        _ sequence: String,
        to handle: FileHandle
    ) -> Result<Void, ProgramStatusError> {
        Result { try handle.write(contentsOf: Data(sequence.utf8)) }
            .mapError { .writeFailed($0.localizedDescription) }
    }
}
