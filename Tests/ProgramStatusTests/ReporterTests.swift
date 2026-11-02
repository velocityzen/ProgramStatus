import FP
import Foundation
import Testing

@testable import ProgramStatus

@Suite("ProgramStatusReporter")
struct ReporterTests {
    @Test("fills in app only when the report has none")
    func inheritsApp() {
        #expect(StatusReport.working().inheriting(app: "photos").app == "photos")
        #expect(StatusReport.working(app: "rsync").inheriting(app: "photos").app == "rsync")
        #expect(StatusReport.working().inheriting(app: nil).app == nil)
    }

    @Test("leaves clear reports alone")
    func clearKeepsOnlyID() {
        #expect(StatusReport.clear(id: "build").inheriting(app: "photos") == .clear(id: "build"))
    }

    @Test("writes the encoded report to its destination")
    func sendWrites() throws {
        let pipe = Pipe()
        let reporter = ProgramStatusReporter(
            app: "photos",
            destination: .fileHandle(pipe.fileHandleForWriting)
        )

        let result = reporter.send(.done("Photos synced"))
        try pipe.fileHandleForWriting.close()

        #expect(result.isSuccess)
        #expect(Self.text(of: pipe) == osc("state=done:app=photos:msg=UGhvdG9zIHN5bmNlZA=="))
    }

    @Test("writes nothing when the report is invalid")
    func invalidWritesNothing() throws {
        let pipe = Pipe()
        let reporter = ProgramStatusReporter(destination: .fileHandle(pipe.fileHandleForWriting))

        let result = reporter.send(.working(progress: 101))
        try pipe.fileHandleForWriting.close()

        #expect(throws: ProgramStatusError.invalidProgress(101)) { try result.get() }
        #expect(Self.text(of: pipe).isEmpty)
    }

    @Test("a pipe is not a terminal")
    func pipeIsNotTerminal() {
        let pipe = Pipe()
        #expect(Destination.requireTerminal(pipe.fileHandleForWriting).isFailure)
    }

    static func text(of pipe: Pipe) -> String {
        String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    }
}
