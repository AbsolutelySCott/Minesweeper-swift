import SwiftUI

/// The visual presentation of one board cell, plus its VoiceOver actions.
/// Touch input is handled once for the whole board by `BoardInteractionLayer`;
/// keeping gestures out of these 480 views is important for large-board
/// scrolling performance.
struct TileView: View {
    let cell: Cell
    let row: Int
    let column: Int
    let side: CGFloat
    let isGameActive: Bool
    let isFlagMode: Bool
    let onAccessibilityActivate: () -> Void
    let onAccessibilityAlternate: () -> Void

    private var cornerRadius: CGFloat {
        min(9, max(2.5, side * 0.17))
    }

    private var numberFontSize: CGFloat {
        min(30, max(10, side * 0.54))
    }

    private var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    /// Small tiles are dense and numerous; skip costly bevels and shadows on
    /// intermediate/expert boards while keeping the richer look for beginner.
    private var usesRichEffects: Bool {
        side >= 30
    }

    var body: some View {
        face
            .frame(width: side, height: side)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("tile-\(row)-\(column)")
            .accessibilityLabel("第 \(row + 1) 行第 \(column + 1) 列")
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(accessibilityHint)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default) {
                guard isGameActive else { return }
                onAccessibilityActivate()
            }
            .accessibilityAction(named: Text(alternateActionName)) {
                guard isGameActive else { return }
                onAccessibilityAlternate()
            }
    }

    // MARK: - Tile faces

    @ViewBuilder
    private var face: some View {
        if cell.isExploded {
            explodedFace
        } else if cell.isRevealed {
            revealedFace
        } else if cell.isFlagged {
            flaggedFace
        } else {
            hiddenFace
        }
    }

    private var hiddenFace: some View {
        ZStack {
            hiddenBackground

            if cell.isFlagged {
                flagGlyph
                wrongFlagBadge
            }
        }
    }

    @ViewBuilder
    private var hiddenBackground: some View {
        if usesRichEffects {
            tileShape
                .fill(
                    LinearGradient(
                        colors: [Theme.hiddenTop, Theme.hiddenBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    tileShape.strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.025)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.7
                    )
                }
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: cornerRadius * 0.65, style: .continuous)
                        .fill(Color.white.opacity(0.045))
                        .frame(width: side * 0.52, height: max(1, side * 0.10))
                        .padding(side * 0.12)
                        .blur(radius: 0.4)
                }
                .shadow(color: Color.black.opacity(0.24), radius: 1.2, x: 0, y: 1.2)
        } else {
            tileShape
                .fill(
                    LinearGradient(
                        colors: [Theme.hiddenTop, Theme.hiddenBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    tileShape.strokeBorder(Color.white.opacity(0.09), lineWidth: 0.6)
                }
        }
    }

    private var flaggedFace: some View {
        hiddenFace
    }

    private var flagGlyph: some View {
        Image(systemName: "flag.fill")
            .font(.system(size: max(8, side * 0.40), weight: .black))
            .foregroundStyle(Theme.goldGradient)
            .shadow(
                color: usesRichEffects ? Color.black.opacity(0.45) : .clear,
                radius: usesRichEffects ? 1 : 0,
                x: 0,
                y: usesRichEffects ? 1 : 0
            )
    }

    @ViewBuilder
    private var wrongFlagBadge: some View {
        if cell.isWrongFlag {
            ZStack {
                Circle()
                    .fill(Theme.danger)
                Image(systemName: "xmark")
                    .font(.system(size: max(4, side * 0.18), weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: max(9, side * 0.34), height: max(9, side * 0.34))
            .overlay {
                Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: 0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(side * 0.06)
        }
    }

    private var revealedFace: some View {
        ZStack {
            revealedBackground

            if cell.hasMine {
                Text("💣")
                    .font(.system(size: max(10, side * 0.58)))
                    .shadow(
                        color: usesRichEffects ? Color.black.opacity(0.45) : .clear,
                        radius: usesRichEffects ? 1 : 0,
                        x: 0,
                        y: usesRichEffects ? 1 : 0
                    )
            } else if cell.adjacentMineCount > 0 {
                numberView
            }
        }
    }

    @ViewBuilder
    private var revealedBackground: some View {
        if usesRichEffects {
            tileShape
                .fill(
                    LinearGradient(
                        colors: [Theme.revealedTop, Theme.revealedBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    tileShape.strokeBorder(Theme.revealedStroke, lineWidth: 0.5)
                }
        } else {
            tileShape
                .fill(Theme.revealedTop)
                .overlay {
                    tileShape.strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
                }
        }
    }

    private var numberText: Text {
        Text("\(cell.adjacentMineCount)")
            .font(.system(size: numberFontSize, weight: .black, design: .rounded))
            .foregroundStyle(Theme.number(cell.adjacentMineCount))
    }

    @ViewBuilder
    private var numberView: some View {
        if usesRichEffects {
            numberText
                .shadow(color: Theme.number(cell.adjacentMineCount).opacity(0.24), radius: 3)
                .minimumScaleFactor(0.7)
        } else {
            numberText
                .minimumScaleFactor(0.7)
        }
    }

    private var explodedFace: some View {
        ZStack {
            explodedBackground

            Circle()
                .fill(Color.white.opacity(usesRichEffects ? 0.18 : 0.07))
                .frame(width: side * 0.7, height: side * 0.7)
                .blur(radius: usesRichEffects ? side * 0.12 : 0)

            Text("💥")
                .font(.system(size: max(10, side * 0.60)))
                .shadow(
                    color: usesRichEffects ? Color.black.opacity(0.35) : .clear,
                    radius: usesRichEffects ? 1 : 0,
                    x: 0,
                    y: usesRichEffects ? 1 : 0
                )
        }
    }

    @ViewBuilder
    private var explodedBackground: some View {
        if usesRichEffects {
            tileShape
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFF8268), Theme.dangerDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    tileShape.strokeBorder(Color.white.opacity(0.32), lineWidth: 0.8)
                }
                .shadow(color: Theme.danger.opacity(0.4), radius: 8, x: 0, y: 0)
        } else {
            tileShape
                .fill(Theme.dangerDeep)
                .overlay {
                    tileShape.strokeBorder(Color.white.opacity(0.22), lineWidth: 0.6)
                }
        }
    }

    // MARK: - Accessibility

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
