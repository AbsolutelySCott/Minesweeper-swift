import SwiftUI

/// The control column used when the phone is held in landscape. The board gets
/// the full remaining height, while every essential control stays reachable in
/// a compact sidebar.
struct LandscapeSidebar: View {
    @Environment(\.gamePalette) private var palette
    let game: MinesweeperGame
    let difficulty: Difficulty
    let bestSeconds: Int?
    let isFlagMode: Bool
    let onSelectDifficulty: (Difficulty) -> Void
    let onReset: () -> Void
    let onToggleFlagMode: () -> Void
    let onShowStats: () -> Void
    let onShowHelp: () -> Void
    let onEnterFullScreen: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            header
            DifficultySelector(selection: difficulty, onSelect: onSelectDifficulty)
            hud
            progressStatus

            Spacer(minLength: 4)

            VStack(spacing: 7) {
                HStack {
                    BestTimeBadge(seconds: bestSeconds)
                    Spacer(minLength: 4)
                    Text(isFlagMode ? "轻点插旗 · 长按翻开" : "拖动 · 双指缩放")
                        .font(.gameRounded(8.5, weight: .medium))
                        .foregroundStyle(palette.tertiaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                HStack(spacing: 7) {
                    SidebarActionChip(
                        icon: isFlagMode ? "flag.fill" : "flag",
                        title: "标记",
                        isActive: isFlagMode,
                        action: onToggleFlagMode
                    )
                    .accessibilityIdentifier("flag-mode-toggle")

                    SidebarActionChip(
                        icon: "chart.bar.xaxis",
                        title: "战绩",
                        action: onShowStats
                    )
                    .accessibilityIdentifier("stats-button")

                    SidebarActionChip(
                        icon: "questionmark",
                        title: "玩法",
                        action: onShowHelp
                    )
                    .accessibilityIdentifier("help-button")
                }
            }
        }
        .padding(13)
        .frame(width: 240)
        .frame(maxHeight: .infinity)
        .glassPanel(cornerRadius: 26)
    }

    private var header: some View {
        HStack(spacing: 8) {
            AppLogoMark(size: 34)

            VStack(alignment: .leading, spacing: 0) {
                Text("扫雷")
                    .font(.gameRounded(21, weight: .bold))
                    .foregroundStyle(palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("\(difficulty.title) · \(difficulty.summary)")
                    .font(.gameRounded(9, weight: .medium))
                    .foregroundStyle(palette.secondaryInk)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Button(action: onEnterFullScreen) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(palette.ink)
                    .frame(width: 30, height: 30)
                    .contentShape(.circle)
                    .background {
                        Circle().fill(palette.ink.opacity(0.06))
                    }
                    .overlay {
                        Circle().strokeBorder(palette.ink.opacity(0.10), lineWidth: 0.7)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("进入全屏模式")
            .accessibilityHint("隐藏侧栏，放大棋盘")
            .accessibilityIdentifier("fullscreen-button")
        }
    }

    private var hud: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(palette.flagDeep)
                    Text("地雷")
                        .font(.gameRounded(8, weight: .bold))
                        .foregroundStyle(palette.secondaryInk)
                }
                Text(TimeFormat.counter(game.remainingMines))
                    .font(.gameMono(19, weight: .bold))
                    .foregroundStyle(palette.ink)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy(duration: 0.2), value: game.remainingMines)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("剩余地雷")
            .accessibilityValue("\(game.remainingMines) 颗")

            Spacer(minLength: 0)

            ResetFaceButton(status: game.status, action: onReset, diameter: 38)

            Spacer(minLength: 0)

            CompactTimer(game: game)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.ink.opacity(0.045))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(palette.ink.opacity(0.075), lineWidth: 0.7)
        }
    }

    private var progressStatus: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(statusTint)
                    .frame(width: 5, height: 5)
                Text(statusText)
                    .font(.gameRounded(9, weight: .semibold))
                    .foregroundStyle(palette.secondaryInk)
                    .lineLimit(1)
                Spacer(minLength: 2)
                if game.status == .playing {
                    Text("\(Int((game.progress * 100).rounded()))%")
                        .font(.gameMono(8.5, weight: .bold))
                        .foregroundStyle(palette.tertiaryInk)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.ink.opacity(0.07))
                    Capsule()
                        .fill(LinearGradient(colors: [palette.accent, palette.mint], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, proxy.size.width * game.progress))
                }
            }
            .frame(height: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("棋盘状态")
        .accessibilityValue(statusText)
    }

    private var statusTint: Color {
        switch game.status {
        case .ready: palette.accent
        case .playing: palette.mint
        case .won: palette.accent
        case .lost: palette.coral
        }
    }

    private var statusText: String {
        switch game.status {
        case .ready: "轻点任意格开始"
        case .playing: "已清理 \(game.revealedSafeCount) / \(game.safeCellCount)"
        case .won: "全部清理完成"
        case .lost: "踩到地雷了"
        }
    }
}

private struct SidebarActionChip: View {
    @Environment(\.gamePalette) private var palette
    let icon: String
    let title: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                Text(title)
                    .font(.gameRounded(10, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isActive ? palette.onAccent : palette.secondaryInk)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background {
                Capsule(style: .continuous)
                    .fill(isActive ? AnyShapeStyle(palette.accentGradient) : AnyShapeStyle(palette.ink.opacity(0.045)))
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(isActive ? Color.clear : palette.ink.opacity(0.09), lineWidth: 0.7)
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isActive ? "已开启" : "已关闭")
        .accessibilityHint(
            title == "标记" ? "切换轻点方格时的操作" : "打开\(title)页面"
        )
    }
}
