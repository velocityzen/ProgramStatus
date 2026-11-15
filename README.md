# ProgramStatus

[![Swift](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvelocityzen%2FProgramStatus%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/velocityzen/ProgramStatus)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvelocityzen%2FProgramStatus%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/velocityzen/ProgramStatus)
[![Documentation](https://img.shields.io/badge/documentation-DocC-purple)](https://swiftpackageindex.com/velocityzen/ProgramStatus/documentation/programstatus)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

Swift encoding of the [Program Status Protocol (OSC 7501)](https://www.superlogical.com/rex/docs/build/program-status), revision 0.4: a terminal escape sequence that tells the terminal whether a program is idle, working, done, blocked on the user, or failed, and why.

The package is a single `ProgramStatus` library for command-line apps, with no dependencies.

## Library

```swift
.package(url: "https://github.com/velocityzen/ProgramStatus", from: "0.5.0"),
// target dependency:
.product(name: "ProgramStatus", package: "ProgramStatus"),
```

```swift
import ProgramStatus

let status = ProgramStatusReporter(app: "photos")  // writes to /dev/tty by default

status.send(.working("Syncing photos", progress: 40))
status.send(.blocked("Password required", kind: .auth))
status.send(.done("Photos synced"))                // send done/error right before exiting
```

Every report replaces its record completely, so `ProgramStatusReporter` adds its `app` to each report that has none. Sending is best-effort: `send` returns a `Result<Void, ProgramStatusError>` you can ignore or check.

Several records at once:

```swift
status.send(.working("Deploying v2.4.1"))
status.send(.working("Pushing image", progress: 40, id: "us-east", title: "US East"))
status.send(.blocked("Approve deploy?", kind: .permission, id: "eu-west", title: "EU West"))
status.send(.clear(id: "us-east"))
```

Pure building blocks:

| Function | Returns |
|---|---|
| `StatusEncoder.encode(_:terminator:)` | `Result<String, ProgramStatusError>` with the full sequence |
| `StatusEncoder.query(terminator:)` | the feature detection query `OSC 7501 ; ? ST` |
| `Capabilities.parse(_:)` | the terminal's reply as `Result<Capabilities, ProgramStatusError>` |
| `StatusText.singleLine(_:)` | text with control characters collapsed, for messages such as `error.localizedDescription` |
| `Destination.write(_:)` | writes a sequence to `.terminal`, `.standardOutput`, `.standardError` or `.fileHandle(_:)` |

`encode` checks every value against the spec (id grammar, `app` charset, progress 0–100, no control characters, byte limits) and fails on the first invalid one. `.standardOutput` and `.standardError` only write while they are a terminal, so pipes and log files never get escape sequences.

The library only builds the query and parses the reply; reading the reply from the terminal (raw mode, timeout) is up to you.

Full API reference: [swiftpackageindex.com/velocityzen/ProgramStatus/documentation/programstatus](https://swiftpackageindex.com/velocityzen/ProgramStatus/documentation/programstatus)

## Example: a command-line tool

The documentation has a complete [`program-status` command](https://swiftpackageindex.com/velocityzen/ProgramStatus/documentation/programstatus/commandlinetool) built on the library with Swift Argument Parser, for reporting status from shell scripts:

```bash
program-status working "Syncing photos" --app photos
program-status done "Photos synced" --app photos
```

## License

[MIT](LICENSE)
