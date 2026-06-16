import Foundation

@MainActor
public final class BeginEndSelectStore: ObservableObject {
    @Published public private(set) var anchor: Int?
    @Published public private(set) var isActive = false

    public init() {}

    public func setBegin(at position: Int) {
        anchor = max(0, position)
        isActive = true
    }

    public func clear() {
        anchor = nil
        isActive = false
    }

    /// Returns selection range from anchor to `end`, or nil if begin not set.
    public func selection(to end: Int, textLength: Int) -> NSRange? {
        guard let anchor else { return nil }
        let lo = min(anchor, end)
        let hi = max(anchor, end)
        guard lo <= textLength else { return nil }
        return NSRange(location: lo, length: min(hi, textLength) - lo)
    }
}
