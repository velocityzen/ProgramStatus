import ArgumentParser
import ProgramStatus

extension ProgramStatusCommand {
    /// The `state` argument. `StatusReport.State` carries kind and progress,
    /// so the command line picks a name and the options fill in the rest.
    enum StateName: String, CaseIterable, ExpressibleByArgument {
        case idle, working, done, blocked, error, clear

        var carriesProgress: Bool {
            self == .working || self == .blocked
        }
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
}

extension StatusReport.BlockedKind: ExpressibleByArgument {}
