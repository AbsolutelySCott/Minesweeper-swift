import SwiftUI

struct TileView: View {
    let cell: Cell
    let row: Int
    let column: Int
    let side: CGFloat
    let isGameActive: Bool
    let isFlagMode: Bool
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var suppressNextTap = false

    private var cornerRadius: CGFloat {
        min(9, max(2.5, side * 0.17))
    }

    private var numberFontSize: CGFloat {
        min(30, max(10, side * 0.54))
    }

    var body: some View {
        Button(action: handleTap) {
            face
                .frame(width: side, height: side)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(TilePressStyle(isEnabled: isGameActive, reduceMotion: reduceMotion))
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.34, maximumDistance: 12)
                .onEnded { _ in
                    handleLongPress()
                }
        )
        .accessibilityIdentifier("tile-\(row)-\(column)")
        .accessibilityLabel("第 \(row + 1) 行第 \(column + 1) 列")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAction(named: Text(secondaryActionName)) {
            guard isGameActive else { return }
            onSecondaryAction()
        }
    }

    private func handleTap() {
        guard isGameActive else { return }
        if suppressNextTap {
            suppressNextTap = false
            return
        }

        if cell.isRevealed {
            // A revealed number is always useful for chording, including in
            // flag mode where a plain tap normally places flags.
            performReveal()
        } else if cell.isFlagged {
            performFlag()
        } else if isFlagMode {
            performFlag()
        } else {
            performReveal()
        }
    }

    private func handleLongPress() {
        guard isGameActive else { return }
        suppressNextTap = true

        if cell.isRevealed {
            performReveal()
        } else if cell.isFlagged {
            performFlag()
        } else if isFlagMode {
            performReveal()
        } else {
            performFlag()
        }

        // If the button canceled its action after the long press, make sure a
        // later, unrelated tap is not swallowed.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            suppressNextTap = false
        }
    }

    private func performReveal() {
        if isFlagMode {
            onSecondaryAction()
        } else {
            onPrimaryAction()
        }
    }

    private func performFlag() {
        if isFlagMode {
            onPrimaryAction()
        } else {
            onSecondaryAction()
        }
    }

    private func performAlternateAccessibilityAction() {
        switch cell.state {
        case .hidden:
            if isFlagMode {
                performReveal()
            } else {
                performFlag()
            }
        case .flagged:
            performFlag()
        case .revealed:
            performReveal()
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
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Theme.hiddenTop, Theme.hiddenBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
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
            .shadow(color: Color.black.opacity(0.24), radius: side >= 28 ? 1.2 : 0.4, x: 0, y: side >= 28 ? 1.2 : 0.5)
    }

    private var flaggedFace: some View {
        hiddenFace
            .overlay {
                Image(systemName: "flag.fill")
                    .font(.system(size: max(8, side * 0.40), weight: .black))
                    .foregroundStyle(Theme.goldGradient)
                    .shadow(color: Color.black.opacity(0.45), radius: 1, x: 0, y: 1)
            }
            .overlay(alignment: .bottomTrailing) {
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
                    .padding(side * 0.06)
                }
            }
    }

    private var revealedFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.revealedTop, Theme.revealedBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Theme.revealedStroke, lineWidth: 0.5)
                }

            if cell.hasMine {
                Text("💣")
                    .font(.system(size: max(10, side * 0.58)))
                    .shadow(color: Color.black.opacity(0.45), radius: 1, x: 0, y: 1)
            } else if cell.adjacentMineCount > 0 {
                Text("\(cell.adjacentMineCount)")
                    .font(.system(size: numberFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.number(cell.adjacentMineCount))
                    .shadow(color: Theme.number(cell.adjacentMineCount).opacity(0.24), radius: 3)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private var explodedFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFF8268), Theme.dangerDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.32), lineWidth: 0.8)
                }
                .shadow(color: Theme.danger.opacity(0.4), radius: 8, x: 0, y: 0)

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: side * 0.7, height: side * 0.7)
                .blur(radius: side * 0.12)

            Text("💥")
                .font(.system(size: max(10, side * 0.60)))
                .shadow(color: Color.black.opacity(0.35), radius: 1, x: 0, y: 1)
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

    private var secondaryActionName: String {
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


private struct TilePressStyle: ButtonStyle {
    let isEnabled: Bool
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isEnabled && configuration.isPressed ? 0.92 : 1)
            .brightness(isEnabled && configuration.isPressed ? 0.04 : 0)
            .animation(reduceMotion ? nil : .snappy(duration: 0.14), value: configuration.isPressed)
    }
}
