# Example: A Command-Line Tool

Report status from shell scripts with a small command built on the library.

## Overview

The package ships only the library. This example wraps it in a
`program-status` command with
[Swift Argument Parser](https://github.com/apple/swift-argument-parser), so a
shell script can report its status:

```bash
program-status working "Syncing photos" --app photos
program-status blocked "Approve deploy?" --kind permission --app deploy
program-status working "Pushing image" --id us-east --title "US East" --progress 40
program-status done "Photos synced" --app photos
program-status clear --id us-east
```

When there is no terminal to write to (CI, cron, a redirected `--to` stream),
the command writes nothing and exits successfully, so scripts can call it
whether or not a terminal is attached. `--dry-run` prints the sequence with
`\e` and `\a` visible instead of sending it.

### The package

```swift
// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "program-status",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/velocityzen/ProgramStatus", from: "0.5.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
    ],
    targets: [
        .executableTarget(
            name: "program-status",
            dependencies: [
                .product(name: "ProgramStatus", package: "ProgramStatus"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        )
    ]
)
```

### The command

The command line picks a state by name, and the options fill in the rest of
the ``StatusReport``. ``StatusEncoder/encode(_:terminator:)`` runs during
validation, so an invalid value is reported as a usage error before anything
is written.

```swift
import ArgumentParser
import ProgramStatus

@main
struct ProgramStatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "program-status",
        abstract: "Tell the terminal what a program is doing (Program Status Protocol, OSC 7501)."
    )

    enum StateName: String, CaseIterable, ExpressibleByArgument {
        case idle, working, done, blocked, error, clear
    }

    enum Output: String, CaseIterable, ExpressibleByArgument {
        case tty, stdout, stderr

        var destination: Destination {
            switch self {
                case .tty: .terminal
                case .stdout: .standardOutput
                case .stderr: .standardError
            }
        }
    }

    @Argument(help: "The state to report: idle, working, done, blocked, error, or clear.")
    var state: StateName

    @Argument(help: "One human-readable line: what the program is doing, waiting for, or finished.")
    var message: String?

    @Option(name: .shortAndLong, help: "Stable program identifier, such as cargo or terraform.")
    var app: String?

    @Option(name: .shortAndLong, help: "Record id for programs that report several records.")
    var id: String?

    @Option(name: .shortAndLong, help: "Short human-readable label for the record.")
    var title: String?

    @Option(name: .shortAndLong, help: "Percentage from 0 to 100. working and blocked only.")
    var progress: Int?

    @Option(name: .shortAndLong, help: "What a blocked program needs: permission, question, or auth.")
    var kind: StatusReport.BlockedKind?

    @Option(help: "Where to write the sequence: tty, stdout, or stderr.")
    var to: Output = .tty

    @Flag(help: "End the sequence with BEL instead of ST (ESC \\).")
    var bel = false

    @Flag(help: "Print the sequence with ESC and BEL shown as \\e and \\a instead of sending it.")
    var dryRun = false

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

    mutating func validate() throws {
        if kind != nil, state != .blocked {
            throw ValidationError("--kind applies to blocked only.")
        }
        if progress != nil, state != .working, state != .blocked {
            throw ValidationError("--progress applies to working and blocked only.")
        }
        if state == .clear, message != nil || app != nil || title != nil {
            throw ValidationError("clear takes only --id.")
        }
        _ = try encoded().mapError { ValidationError($0.localizedDescription) }.get()
    }

    func run() throws {
        try encoded()
            .flatMap { sequence in
                dryRun
                    ? Destination.fileHandle(.standardOutput).write(visible(sequence) + "\n")
                    : to.destination.write(sequence)
            }
            // No terminal means nothing to report to, which is not a failure for a script.
            .flatMapError { $0 == .noTerminal ? .success(()) : .failure($0) }
            .get()
    }

    func visible(_ sequence: String) -> String {
        sequence
            .replacing("\u{1B}", with: "\\e")
            .replacing("\u{07}", with: "\\a")
    }
}

extension StatusReport.BlockedKind: @retroactive ExpressibleByArgument {}
```
