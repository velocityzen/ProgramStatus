# ``ProgramStatus``

Tell the terminal what a program is doing with the Program Status Protocol (OSC 7501).

## Overview

The [Program Status Protocol](https://www.superlogical.com/rex/docs/build/program-status)
is a terminal escape sequence, `ESC ] 7501 ; key=value:… ST`, through which a
program reports whether it is idle, working, done, blocked on the user, or
failed, and why. This library encodes revision 0.4.

```swift
import ProgramStatus

let status = ProgramStatusReporter(app: "photos")

status.send(.working("Syncing photos", progress: 40))
status.send(.blocked("Password required", kind: .auth))
status.send(.done("Photos synced"))
```

Each report replaces its record completely, so ``ProgramStatusReporter`` adds
its `app` to every report that has none. Sending is best-effort:
``ProgramStatusReporter/send(_:)`` returns a `Result` you can ignore or check.

### Several records

Give each record an `id`, a `/`-separated path, to report several at once.
``StatusReport/clear(id:)`` removes a record and every record beneath it.

```swift
status.send(.working("Pushing image", progress: 40, id: "us-east", title: "US East"))
status.send(.blocked("Approve deploy?", kind: .permission, id: "eu-west", title: "EU West"))
status.send(.clear(id: "us-east"))
```

### Validation

``StatusEncoder/encode(_:terminator:)`` checks every value against the
specification — the id grammar, the `app` character set, progress from 0 to
100, single-line text, and byte limits — and fails with the first
``ProgramStatusError`` it finds. Pass multi-line text such as an error
description through ``StatusText/singleLine(_:)`` first.

### Where reports go

Reports go to the controlling terminal, `/dev/tty`, by default, so they reach
the user even when standard output is redirected.
``Destination/standardOutput`` and ``Destination/standardError`` only write
while they are a terminal, so pipes and log files never get escape sequences.
With no terminal, ``Destination/write(_:)`` fails with
``ProgramStatusError/noTerminal``.

### Feature detection

``StatusEncoder/query(terminator:)`` builds the query `OSC 7501 ; ? ST`, and
``Capabilities/parse(_:)`` reads the terminal's reply. Reading the reply from
the terminal (raw mode, a timeout) is up to the caller.

## Topics

### Reporting

- ``ProgramStatusReporter``
- ``StatusReport``
- ``StatusText``

### Encoding

- ``StatusEncoder``
- ``Terminator``

### Writing

- ``Destination``

### Feature detection

- ``Capabilities``

### Errors

- ``ProgramStatusError``
