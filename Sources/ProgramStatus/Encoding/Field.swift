import FP
import Foundation

/// One `key=value` pair of a report, before validation.
enum Field {
    case state(String)
    case kind(StatusReport.BlockedKind)
    case id(String)
    case app(String)
    case title(String)
    case progress(Int)
    case message(String)
}

extension Field {
    /// The pairs a report carries, in the order the specification's examples use.
    static func fields(of report: StatusReport) -> [Field] {
        let fields: [Field?] = [
            .state(report.state.name),
            report.state.kind.map(Field.kind),
            report.id.map(Field.id),
            report.app.map(Field.app),
            report.title.map(Field.title),
            report.state.progress.map(Field.progress),
            report.message.map(Field.message),
        ]
        return fields.compact()
    }

    /// Validates the value and renders it as `key=value`.
    func encoded() -> Result<String, ProgramStatusError> {
        switch self {
            case .state(let name):
                .success(Self.pair("state", name))
            case .kind(let kind):
                .success(Self.pair("kind", kind.rawValue))
            case .id(let id):
                Validate.id(id).map { Self.pair("id", $0) }
            case .app(let app):
                Validate.app(app).map { Self.pair("app", $0) }
            case .title(let title):
                Validate.text(title, .title).map(Self.base64).map { Self.pair("title", $0) }
            case .progress(let progress):
                Validate.progress(progress).map { Self.pair("progress", String($0)) }
            case .message(let message):
                Validate.text(message, .message).map(Self.base64).map { Self.pair("msg", $0) }
        }
    }

    static func pair(_ key: String, _ value: String) -> String {
        "\(key)=\(value)"
    }

    static func base64(_ text: String) -> String {
        Data(text.utf8).base64EncodedString()
    }
}
