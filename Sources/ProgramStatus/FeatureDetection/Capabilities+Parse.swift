import FP
import Foundation

extension Capabilities {
    /// Parses a terminal's reply to ``StatusEncoder/query(terminator:)``, such as
    /// `ESC ] 7501 ; ? : states=idle,working : kinds=auth ST`.
    ///
    /// Bytes around the reply (a device attributes answer, stray input) are
    /// skipped. Unknown and malformed pairs are ignored; a repeated key keeps
    /// its last value.
    public static func parse(_ reply: String) -> Result<Capabilities, ProgramStatusError> {
        body(of: reply)
            .map(items)
            .flatMap(afterQueryMarker)
            .map(pairs)
            .map(capabilities)
    }
}

extension Capabilities {
    /// The text between `OSC 7501 ;` and the first ST or BEL after it.
    static func body(of reply: String) -> Result<Substring, ProgramStatusError> {
        Result.fromOptional(afterIntroducer(reply).flatMap(beforeTerminator), error: .invalidReply)
    }

    static func afterIntroducer(_ reply: String) -> Substring? {
        reply.firstRange(of: StatusEncoder.introducer).map { reply[$0.upperBound...] }
    }

    /// ST starts with ESC, so the first ESC or BEL ends the body.
    static func beforeTerminator(_ text: Substring) -> Substring? {
        text.firstIndex { $0 == "\u{1B}" || $0 == "\u{07}" }.map { text[..<$0] }
    }

    static func items(_ body: Substring) -> [String] {
        body.split(separator: ":", omittingEmptySubsequences: false).map(trimmed)
    }

    static func afterQueryMarker(_ items: [String]) -> Result<[String], ProgramStatusError> {
        items.first == "?" ? .success(Array(items.dropFirst())) : .failure(.invalidReply)
    }

    static func pairs(_ items: [String]) -> [String: String] {
        Dictionary(items.compactMap(pair), uniquingKeysWith: { _, last in last })
    }

    /// `key=value`, or `nil` when there is no `=` or the key is empty.
    static func pair(_ item: String) -> (String, String)? {
        let parts = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        let key = trimmed(parts[0])
        return key.isEmpty ? nil : (key, trimmed(parts[1]))
    }

    static func capabilities(_ pairs: [String: String]) -> Capabilities {
        Capabilities(
            states: pairs["states"].map(list) ?? baseline.states,
            kinds: pairs["kinds"].map(list) ?? baseline.kinds
        )
    }

    static func list(_ value: String) -> Set<String> {
        Set(value.split(separator: ",").map(trimmed).filter { !$0.isEmpty })
    }

    static func trimmed(_ text: some StringProtocol) -> String {
        text.trimmingCharacters(in: .whitespaces)
    }
}
