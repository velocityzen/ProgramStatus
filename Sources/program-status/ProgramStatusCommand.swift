import ArgumentParser
import FP
import ProgramStatus

@main
struct ProgramStatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "program-status",
        abstract: "Tell the terminal what a program is doing (Program Status Protocol, OSC 7501).",
        discussion: """
            Writes one report to the controlling terminal. When there is no terminal \
            to write to (CI, cron, a redirected --to stream) it does nothing and exits \
            successfully, so scripts can call it unconditionally.

            Examples:
              program-status working "Syncing photos" --app photos
              program-status blocked "Approve deploy?" --kind permission --app deploy
              program-status working "Pushing image" --id us-east --title "US East" --progress 40
              program-status done "Photos synced" --app photos
              program-status clear --id us-east
            """
    )

    @Argument(help: "The state to report: idle, working, done, blocked, error, or clear.")
    var state: StateName

    @Argument(help: "One human-readable line: what the program is doing, waiting for, or finished.")
    var message: String?

    @Option(name: .shortAndLong, help: "Stable program identifier, such as cargo or terraform.")
    var app: String?

    @Option(
        name: .shortAndLong,
        help: "Record id for programs that report several records, such as build/test."
    )
    var id: String?

    @Option(name: .shortAndLong, help: "Short human-readable label for the record.")
    var title: String?

    @Option(name: .shortAndLong, help: "Percentage from 0 to 100. working and blocked only.")
    var progress: Int?

    @Option(
        name: .shortAndLong,
        help: "What a blocked program needs: permission, question, or auth."
    )
    var kind: StatusReport.BlockedKind?

    @Option(help: "Where to write the sequence: tty, stdout, or stderr.")
    var to: Output = .tty

    @Flag(help: "End the sequence with BEL instead of ST (ESC \\).")
    var bel = false

    @Flag(help: "Print the sequence with ESC and BEL shown as \\e and \\a instead of sending it.")
    var dryRun = false

    mutating func validate() throws {
        if kind != nil, state != .blocked {
            throw ValidationError("--kind applies to blocked only.")
        }
        if progress != nil, !state.carriesProgress {
            throw ValidationError("--progress applies to working and blocked only.")
        }
        if state == .clear, message != nil || app != nil || title != nil {
            throw ValidationError("clear takes only --id.")
        }
        _ = try encoded()
            .mapError { ValidationError($0.localizedDescription) }
            .get()
    }

    func run() throws {
        try encoded()
            .flatMap(deliver)
            .orElse(Self.ignoringNoTerminal)
            .get()
    }
}

extension ProgramStatusCommand {
    var report: StatusReport {
        switch state {
            case .idle: .idle(message, app: app, id: id, title: title)
            case .working: .working(message, progress: progress, app: app, id: id, title: title)
            case .done: .done(message, app: app, id: id, title: title)
            case .blocked:
                .blocked(message, kind: kind, progress: progress, app: app, id: id, title: title)
            case .error: .error(message, app: app, id: id, title: title)
            case .clear: .clear(id: id)
        }
    }

    func encoded() -> Result<String, ProgramStatusError> {
        StatusEncoder.encode(report, terminator: bel ? .bel : .st)
    }

    func deliver(_ sequence: String) -> Result<Void, ProgramStatusError> {
        dryRun
            ? Destination.fileHandle(.standardOutput).write(Self.visible(sequence) + "\n")
            : to.destination.write(sequence)
    }

    /// No terminal means nothing to report to, which is not a failure for a script.
    static func ignoringNoTerminal(
        _ error: ProgramStatusError
    ) -> Result<Void, ProgramStatusError> {
        error == .noTerminal ? .success(()) : .failure(error)
    }

    static func visible(_ sequence: String) -> String {
        sequence
            .replacing("\u{1B}", with: "\\e")
            .replacing("\u{07}", with: "\\a")
    }
}
