import SwiftUI

struct SplitResizeHandle: View {
    enum Axis {
        case horizontal
        case vertical
    }

    let axis: Axis
    let onDrag: (CGFloat) -> Void

    @State private var lastTranslation: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(
                width: axis == .vertical ? 5 : nil,
                height: axis == .horizontal ? 5 : nil
            )
            .contentShape(Rectangle())
            .overlay {
                if axis == .horizontal {
                    Capsule()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 36, height: 3)
                } else {
                    Capsule()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 3, height: 36)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        let delta = (axis == .horizontal ? value.translation.height : value.translation.width) - lastTranslation
                        lastTranslation = axis == .horizontal ? value.translation.height : value.translation.width
                        onDrag(delta)
                    }
                    .onEnded { _ in lastTranslation = 0 }
            )
            .onHover { inside in
                if inside {
                    if axis == .horizontal { NSCursor.resizeUpDown.push() }
                    else { NSCursor.resizeLeftRight.push() }
                } else {
                    NSCursor.pop()
                }
            }
    }
}

struct ResizableSidePanel<Content: View>: View {
    @Binding var width: CGFloat
    var minWidth: CGFloat = 120
    var maxWidth: CGFloat = 520
  /// `.trailing` = resize handle on the right (left dock panels). `.leading` = handle on the left (right dock panels).
    var handleEdge: HorizontalEdge
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            if handleEdge == .leading {
                SplitResizeHandle(axis: .vertical) { delta in
                    width = min(maxWidth, max(minWidth, width - delta))
                }
            }
            content()
                .frame(width: width)
            if handleEdge == .trailing {
                SplitResizeHandle(axis: .vertical) { delta in
                    width = min(maxWidth, max(minWidth, width + delta))
                }
            }
        }
    }
}

struct ResizableVSplit<Top: View, Bottom: View>: View {
    @Binding var ratio: CGFloat
    @ViewBuilder let top: () -> Top
    @ViewBuilder let bottom: () -> Bottom

    var body: some View {
        GeometryReader { geo in
            let total = max(geo.size.height, 120)
            let topHeight = max(60, min(total - 60, total * ratio))
            VStack(spacing: 0) {
                top()
                    .frame(height: topHeight)
                SplitResizeHandle(axis: .horizontal) { delta in
                    let newRatio = ratio + delta / total
                    ratio = min(0.85, max(0.15, newRatio))
                }
                bottom()
                    .frame(maxHeight: .infinity)
            }
        }
    }
}

struct ResizableHSplit<Leading: View, Trailing: View>: View {
    @Binding var ratio: CGFloat
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        GeometryReader { geo in
            let total = max(geo.size.width, 120)
            let leadingWidth = max(80, min(total - 80, total * ratio))
            HStack(spacing: 0) {
                leading()
                    .frame(width: leadingWidth)
                SplitResizeHandle(axis: .vertical) { delta in
                    let newRatio = ratio + delta / total
                    ratio = min(0.85, max(0.15, newRatio))
                }
                trailing()
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
