/// Hard caps from the specification's Limits section.
enum Limits {
    /// An `app` value or one id segment.
    static let nameLength = 1...32
    static let idBytes = 128
    static let idDepth = 8
    static let progress = 0...100

    /// Decoded UTF-8 bytes. The encoded caps (256 and 2732) follow from these.
    static func textBytes(_ field: ProgramStatusError.TextField) -> Int {
        switch field {
            case .title: 192
            case .message: 2048
        }
    }
}

/// One check per value a report carries; each passes the value through or fails.
enum Validate {
    static func id(_ id: String) -> Result<String, ProgramStatusError> {
        isID(id) ? .success(id) : .failure(.invalidID(id))
    }

    static func app(_ app: String) -> Result<String, ProgramStatusError> {
        isName(app) ? .success(app) : .failure(.invalidApp(app))
    }

    static func progress(_ value: Int) -> Result<Int, ProgramStatusError> {
        Limits.progress.contains(value) ? .success(value) : .failure(.invalidProgress(value))
    }

    static func text(
        _ text: String,
        _ field: ProgramStatusError.TextField
    ) -> Result<String, ProgramStatusError> {
        singleLine(text, field).flatMap { fits($0, field) }
    }
}

extension Validate {
    /// `segment ("/" segment)*`, at most 8 levels and 128 bytes.
    static func isID(_ id: String) -> Bool {
        let segments = id.split(separator: "/", omittingEmptySubsequences: false)
        return id.utf8.count <= Limits.idBytes
            && segments.count <= Limits.idDepth
            && segments.allSatisfy(isName)
    }

    /// `[A-Za-z0-9_.+-]{1,32}`: an `app` value or one id segment.
    static func isName(_ name: some StringProtocol) -> Bool {
        Limits.nameLength.contains(name.utf8.count)
            && name.unicodeScalars.allSatisfy(isNameScalar)
    }

    static func isNameScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar {
            case "A"..."Z", "a"..."z", "0"..."9", "_", ".", "+", "-": true
            default: false
        }
    }

    /// U+0000–U+001F, U+007F, and U+0080–U+009F, newline and tab included.
    static func isControl(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value < 0x20 || (0x7F...0x9F).contains(scalar.value)
    }

    static func singleLine(
        _ text: String,
        _ field: ProgramStatusError.TextField
    ) -> Result<String, ProgramStatusError> {
        text.unicodeScalars.contains(where: isControl)
            ? .failure(.controlCharacter(field))
            : .success(text)
    }

    static func fits(
        _ text: String,
        _ field: ProgramStatusError.TextField
    ) -> Result<String, ProgramStatusError> {
        let bytes = text.utf8.count
        let limit = Limits.textBytes(field)
        return bytes <= limit
            ? .success(text)
            : .failure(.textTooLong(field, bytes: bytes, limit: limit))
    }
}
