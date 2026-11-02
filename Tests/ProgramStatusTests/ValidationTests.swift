import FP
import Testing

@testable import ProgramStatus

@Suite("Validation")
struct ValidationTests {
    @Test(
        "accepts ids that match the grammar",
        arguments: [
            "build",
            "build/test",
            "a.b_c+d-e/F9",
            String(repeating: "s", count: 32),
            Array(repeating: "x", count: 8).joined(separator: "/"),
        ]
    )
    func validID(id: String) {
        #expect(Validate.id(id) == .success(id))
    }

    @Test(
        "rejects ids outside the grammar",
        arguments: [
            "",
            "/build",
            "build/",
            "build//test",
            "build test",
            "build:test",
            "über",
            String(repeating: "s", count: 33),
            Array(repeating: "x", count: 9).joined(separator: "/"),
            Array(repeating: String(repeating: "x", count: 32), count: 4).joined(separator: "/"),
        ]
    )
    func invalidID(id: String) {
        #expect(Validate.id(id) == .failure(.invalidID(id)))
    }

    @Test(
        "app is 1 to 32 name characters",
        arguments: ["cargo", "claude-code", "a", String(repeating: "a", count: 32)]
    )
    func validApp(app: String) {
        #expect(Validate.app(app) == .success(app))
    }

    @Test(
        "rejects other apps",
        arguments: ["", "my app", "a/b", "a=b", String(repeating: "a", count: 33)]
    )
    func invalidApp(app: String) {
        #expect(Validate.app(app) == .failure(.invalidApp(app)))
    }

    @Test("progress is 0 to 100")
    func progress() {
        #expect(Validate.progress(0) == .success(0))
        #expect(Validate.progress(100) == .success(100))
        #expect(Validate.progress(-1) == .failure(.invalidProgress(-1)))
        #expect(Validate.progress(101) == .failure(.invalidProgress(101)))
    }

    @Test(
        "rejects C0, DEL, and C1 control characters",
        arguments: [
            "line\nbreak", "tab\there", "nul\u{0}", "esc\u{1B}[0m", "del\u{7F}", "nel\u{85}",
            "csi\u{9B}",
        ]
    )
    func controlCharacters(text: String) {
        #expect(Validate.text(text, .message) == .failure(.controlCharacter(.message)))
        #expect(Validate.text(text, .title) == .failure(.controlCharacter(.title)))
    }

    @Test("caps decoded UTF-8 bytes, not characters")
    func textLimits() {
        let title = String(repeating: "é", count: 97)
        let message = String(repeating: "m", count: 2049)

        #expect(Validate.text(String(repeating: "t", count: 192), .title).isSuccess)
        #expect(
            Validate.text(title, .title) == .failure(.textTooLong(.title, bytes: 194, limit: 192))
        )
        #expect(
            Validate.text(message, .message)
                == .failure(.textTooLong(.message, bytes: 2049, limit: 2048))
        )
    }

    @Test("singleLine makes multi-line text reportable")
    func singleLine() throws {
        let text = StatusText.singleLine("Error:\n  detail\r\n\tmore\u{1B}")

        #expect(text == "Error: detail more")
        #expect(try StatusEncoder.encode(.error(text)).get().isEmpty == false)
        #expect(StatusText.singleLine("\n\n") == "")
    }
}
