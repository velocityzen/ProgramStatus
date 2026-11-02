import Foundation

/// Helpers for the free-text `message` and `title` values.
public enum StatusText {
    /// Collapses text onto one line: every run of control characters (newlines,
    /// tabs, ESC, …) becomes a single space, and the pieces are trimmed.
    ///
    /// Reports refuse control characters, so pass multi-line text such as an
    /// error description through this first:
    ///
    /// ```swift
    /// status.send(.error(StatusText.singleLine(error.localizedDescription)))
    /// ```
    public static func singleLine(_ text: String) -> String {
        text.unicodeScalars
            .split(whereSeparator: Validate.isControl)
            .map { Substring($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
