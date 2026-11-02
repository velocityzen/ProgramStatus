import FP
import Testing

@testable import ProgramStatus

@Suite("Capabilities")
struct CapabilitiesTests {
    @Test("reads states and kinds from the reply")
    func fullReply() {
        let reply = osc("?:states=idle,working,done,blocked,error,paused:kinds=permission,auth")
        let expected = Capabilities(
            states: ["idle", "working", "done", "blocked", "error", "paused"],
            kinds: ["permission", "auth"]
        )
        #expect(Capabilities.parse(reply) == .success(expected))
    }

    @Test("a bare ? means the baseline lists")
    func bareReply() {
        #expect(Capabilities.parse(osc("?")) == .success(.baseline))
        #expect(Capabilities.parse("\u{1B}]7501;?\u{07}") == .success(.baseline))
    }

    @Test("whitespace around keys and values is removed")
    func whitespace() {
        let reply = osc(" ? : states = idle , working : kinds = auth ")
        #expect(
            Capabilities.parse(reply)
                == .success(Capabilities(states: ["idle", "working"], kinds: ["auth"]))
        )
    }

    @Test("unknown and malformed pairs are ignored, the last repeat wins")
    func lenientPairs() {
        let reply = osc("?:color=yes:junk:=x:kinds=auth:kinds=question")
        #expect(
            Capabilities.parse(reply)
                == .success(Capabilities(states: Capabilities.baseline.states, kinds: ["question"]))
        )
    }

    @Test("skips bytes around the reply, such as a device attributes answer")
    func surroundingBytes() {
        let reply = "x" + osc("?:kinds=auth") + "\u{1B}[?62;22c"
        #expect(Capabilities.parse(reply).map(\.kinds) == .success(["auth"]))
    }

    @Test(
        "rejects anything that is not a reply",
        arguments: [
            "", "\u{1B}[?62;22c", osc("state=idle"), "\u{1B}]7501;?", "\u{1B}]7502;?\u{1B}\\",
        ]
    )
    func invalidReply(reply: String) {
        #expect(Capabilities.parse(reply) == .failure(.invalidReply))
    }

    @Test("supports checks states and kinds; clear is always accepted")
    func supports() {
        let capabilities = Capabilities(states: ["working"], kinds: ["auth"])

        #expect(capabilities.supports(.working(progress: 10)))
        #expect(capabilities.supports(.clear))
        #expect(!capabilities.supports(.done))
        #expect(capabilities.supports(.auth))
        #expect(!capabilities.supports(.question))
    }
}
