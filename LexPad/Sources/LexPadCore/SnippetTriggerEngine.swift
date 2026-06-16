import Foundation

public enum SnippetTriggerEngine {
    /// Returns expanded snippet body if `text` ends with a registered trigger after the last edit.
    public static func expansion(
        in text: String,
        caretLocation: Int,
        snippets: [Snippet]
    ) -> (body: String, triggerRange: NSRange)? {
        let triggers = snippets.compactMap { snippet -> (String, Snippet)? in
            guard let trigger = snippet.trigger, !trigger.isEmpty else { return nil }
            return (trigger, snippet)
        }
        guard !triggers.isEmpty else { return nil }

        let ns = text as NSString
        let safeCaret = min(max(0, caretLocation), ns.length)
        let prefix = ns.substring(to: safeCaret)

        for (trigger, snippet) in triggers.sorted(by: { $0.0.count > $1.0.count }) {
            guard prefix.hasSuffix(trigger) else { continue }
            let start = safeCaret - trigger.count
            guard start >= 0 else { continue }
            if start > 0 {
                let before = ns.character(at: start - 1)
                if isWordChar(before) { continue }
            }
            let range = NSRange(location: start, length: trigger.count)
            return (snippet.body, range)
        }
        return nil
    }

    private static func isWordChar(_ code: unichar) -> Bool {
        guard let scalar = UnicodeScalar(code) else { return false }
        return CharacterSet.alphanumerics.contains(scalar) || scalar == "_"
    }
}
