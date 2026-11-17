import SwiftUI

/// The invisible accessibility grid laid over the Canvas board. These cells do
/// no drawing work at all, but keep every board position individually
/// focusable and actionable in VoiceOver and UI tests.
struct BoardAccessibilityGrid: View {
    let cells: [Cell]
    let configuration: BoardConfiguration
    let tile: CGFloat
    let spacing: CGFloat
    let isGameActive: Bool
    let isFlagMode: Bool
    let onActivate: (Int) -> Void
    let onAlternate: (Int) -> Void

    private var contentSize: CGSize {
        CGSize(
            width: CGFloat(configuration.columns) * tile + CGFloat(configuration.columns - 1) * spacing,
            height: CGFloat(configuration.rows) * tile + CGFloat(configuration.rows - 1) * spacing
        )
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<configuration.rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<configuration.columns, id: \.self) { column in
                        let index = configuration.index(row: row, column: column)

                        BoardCellAccessibility(
                            cell: cells[index],
                            row: row,
                            column: column,
                            side: tile,
                            isGameActive: isGameActive,
                            isFlagMode: isFlagMode,
                            onActivate: { onActivate(index) },
                            onAlternate: { onAlternate(index) }
                        )
                    }
                }
            }
        }
        .frame(width: contentSize.width, height: contentSize.height)
        .accessibilityElement(children: .contain)
    }
}

private struct BoardCellAccessibility: View {
    let cell: Cell
    let row: Int
    let column: Int
    let side: CGFloat
    let isGameActive: Bool
    let isFlagMode: Bool
    let onActivate: () -> Void
    let onAlternate: () -> Void

    var body: some View {
        Color.clear
            .frame(width: side, height: side)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("tile-\(row)-\(column)")
            .accessibilityLabel("第 \(row + 1) 行第 \(column + 1) 列")
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(accessibilityHint)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default) {
                guard isGameActive else { return }
                onActivate()
            }
            .accessibilityAction(named: Text(alternateActionName)) {
                guard isGameActive else { return }
                onAlternate()
            }
    }

    private var accessibilityValue: String {
        if cell.isExploded { return "引爆的地雷" }
        switch cell.state {
        case .flagged:
            return cell.isWrongFlag ? "插错的旗子" : "已插旗"
        case .hidden:
            return "未翻开"
        case .revealed:
            if cell.hasMine { return "地雷" }
            if cell.adjacentMineCount == 0 { return "空白，周围没有地雷" }
            return "周围有 \(cell.adjacentMineCount) 颗地雷"
        }
    }

    private var accessibilityHint: String {
        guard isGameActive else { return "游戏已经结束" }
        switch cell.state {
        case .hidden:
            return isFlagMode
                ? "轻点插旗，长按翻开"
                : "轻点翻开，长按插旗"
        case .revealed where cell.adjacentMineCount > 0:
            return "轻点可翻开周围方格"
        case .flagged:
            return isFlagMode
                ? "轻点取消旗子"
                : "轻点或长按取消旗子"
        case .revealed:
            return "已翻开"
        }
    }

    private var alternateActionName: String {
        switch cell.state {
        case .hidden:
            return isFlagMode ? "翻开" : "插旗"
        case .flagged:
            return "取消标记"
        case .revealed:
            return "翻开周围"
        }
    }
}
