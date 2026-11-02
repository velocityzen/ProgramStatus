import FP
import FPBracket
import Foundation

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
    static func writeToTerminal(_ sequence: String) -> Result<Void, ProgramStatusError> {
        let withTerminal = openTerminal()
        return withTerminal { write(sequence, to: $0) }
    }

    /// Opens `/dev/tty` for one write and closes it afterwards. Opening fails
    /// when the process has no controlling terminal (CI, cron, daemons).
    static func openTerminal() -> Bracket<FileHandle, ProgramStatusError> {
        Bracket(
            acquire: {
                Result.fromOptional(FileHandle(forWritingAtPath: "/dev/tty"), error: .noTerminal)
            },
            dispose: close
        )
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

    static func close(_ handle: FileHandle) -> Result<Void, ProgramStatusError> {
        Result { try handle.close() }
            .mapError { .writeFailed($0.localizedDescription) }
    }
}
