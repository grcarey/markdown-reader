// Pairs editor and preview heading offsets into matching breakpoint lists. Starts at (0, 0), ends at the max scrolls,
// and drops any heading that does not strictly advance in both axes (so the map stays monotonic and invertible).
public func scrollBreakpoints(editor: [Double], preview: [Double], editorMax: Double, previewMax: Double) -> (editor: [Double], preview: [Double]) {
    var e = [0.0], p = [0.0]
    for (ey, py) in zip(editor, preview) where ey > e.last! && py > p.last! && ey < editorMax && py < previewMax {
        e.append(ey)
        p.append(py)
    }
    if editorMax > e.last!, previewMax > p.last! {
        e.append(editorMax)
        p.append(previewMax)
    }
    return (e, p)
}

// Piecewise linear map of y from one breakpoint list to the other (either direction); clamps beyond the ends.
public func mapScroll(_ y: Double, from: [Double], to: [Double]) -> Double {
    guard from.count > 1, from.count == to.count else { return to.first ?? 0 }
    let y = min(max(y, from[0]), from[from.count - 1])
    let i = (from.firstIndex { $0 >= y } ?? from.count - 1).clamped(1, from.count - 1)
    let t = (y - from[i - 1]) / (from[i] - from[i - 1])
    return to[i - 1] + t * (to[i] - to[i - 1])
}

private extension Int {
    func clamped(_ lo: Int, _ hi: Int) -> Int { Swift.min(Swift.max(self, lo), hi) }
}
