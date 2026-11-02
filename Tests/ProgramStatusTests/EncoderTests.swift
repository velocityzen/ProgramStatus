import FP
import Testing

@testable import ProgramStatus

@Suite("StatusEncoder")
struct EncoderTests {
    /// Every report from the specification's Examples section, byte for byte.
    static let specExamples: [(StatusReport, String)] = [
        (
            .blocked(
                "Apply 3 to add, 1 to change, 0 to destroy?",
                kind: .permission,
                app: "terraform"
            ),
            "state=blocked:kind=permission:app=terraform:msg=QXBwbHkgMyB0byBhZGQsIDEgdG8gY2hhbmdlLCAwIHRvIGRlc3Ryb3k/"
        ),
        (
            .working("Installing updates", app: "brew"),
            "state=working:app=brew:msg=SW5zdGFsbGluZyB1cGRhdGVz"
        ),
        (
            .blocked("Password required to install updates", kind: .auth, app: "brew"),
            "state=blocked:kind=auth:app=brew:msg=UGFzc3dvcmQgcmVxdWlyZWQgdG8gaW5zdGFsbCB1cGRhdGVz"
        ),
        (
            .done("Upgraded 12 packages", app: "brew"),
            "state=done:app=brew:msg=VXBncmFkZWQgMTIgcGFja2FnZXM="
        ),
        (
            .working("Deploying v2.4.1", app: "deploy"),
            "state=working:app=deploy:msg=RGVwbG95aW5nIHYyLjQuMQ=="
        ),
        (
            .working("Pushing image", progress: 40, id: "us-east", title: "US East"),
            "state=working:id=us-east:title=VVMgRWFzdA==:progress=40:msg=UHVzaGluZyBpbWFnZQ=="
        ),
        (
            .blocked(
                "Approve deploy to eu-west (production)?",
                kind: .permission,
                id: "eu-west",
                title: "EU West"
            ),
            "state=blocked:kind=permission:id=eu-west:title=RVUgV2VzdA==:msg=QXBwcm92ZSBkZXBsb3kgdG8gZXUtd2VzdCAocHJvZHVjdGlvbik/"
        ),
        (
            .done("Healthy", id: "us-east", title: "US East"),
            "state=done:id=us-east:title=VVMgRWFzdA==:msg=SGVhbHRoeQ=="
        ),
        (
            .clear(id: "us-east"),
            "state=clear:id=us-east"
        ),
        (
            .done("Deployed to 3 regions", app: "deploy"),
            "state=done:app=deploy:msg=RGVwbG95ZWQgdG8gMyByZWdpb25z"
        ),
    ]

    @Test("matches the specification's examples", arguments: specExamples)
    func specExample(report: StatusReport, body: String) throws {
        #expect(try StatusEncoder.encode(report).get() == osc(body))
    }

    @Test("a bare state needs nothing else")
    func bareStates() throws {
        #expect(try StatusEncoder.encode(.idle()).get() == osc("state=idle"))
        #expect(try StatusEncoder.encode(.error()).get() == osc("state=error"))
        #expect(try StatusEncoder.encode(.clear()).get() == osc("state=clear"))
    }

    @Test("blocked carries both kind and progress")
    func blockedWithProgress() throws {
        let report = StatusReport.blocked(kind: .question, progress: 75)
        #expect(
            try StatusEncoder.encode(report).get() == osc("state=blocked:kind=question:progress=75")
        )
    }

    @Test("BEL terminates instead of ST")
    func belTerminator() throws {
        let sequence = try StatusEncoder.encode(.idle(), terminator: .bel).get()
        #expect(sequence == "\u{1B}]7501;state=idle\u{07}")
    }

    @Test("text is base64 of UTF-8")
    func utf8Message() throws {
        let sequence = try StatusEncoder.encode(.done("Déploiement ✅")).get()
        #expect(sequence == osc("state=done:msg=RMOpcGxvaWVtZW50IOKchQ=="))
    }

    @Test("the feature detection query")
    func query() {
        #expect(StatusEncoder.query() == osc("?"))
        #expect(StatusEncoder.query(terminator: .bel) == "\u{1B}]7501;?\u{07}")
    }

    @Test("the largest legal report fits the 4096-byte sequence cap")
    func largestReport() throws {
        let id =
            ([String(repeating: "a", count: 16)]
            + Array(repeating: String(repeating: "b", count: 15), count: 7))
            .joined(separator: "/")
        let report = StatusReport(
            state: .blocked(kind: .permission, progress: 100),
            id: id,
            app: String(repeating: "c", count: 32),
            title: String(repeating: "t", count: 192),
            message: String(repeating: "m", count: 2048)
        )
        let sequence = try StatusEncoder.encode(report).get()

        #expect(id.utf8.count == 128)
        #expect(sequence.utf8.count < 3300)
    }

    @Test("the first invalid value fails the whole report")
    func invalidReport() {
        let report = StatusReport.working("Syncing\n", progress: 140, app: "bad app")
        #expect(StatusEncoder.encode(report) == .failure(.invalidApp("bad app")))
    }
}
