import SwiftUI

/// The compact controls that stay on screen while the board is in full-screen
/// mode. Everything non-essential is hidden so the board gets as much room as
/// possible.
struct FullScreenHUD: View {
    @Environment(\.gamePalette) private var palette
    let game: MinesweeperGame
    let difficulty: Difficulty
    let isFlagMode: Bool
    let onExit: () -> Void
    let onReset: () -> Void
    let onToggleFlagMode: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            Button(action: onExit) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(palette.ink)
                    .frame(width: 33, height: 33)
                    .contentShape(.circle)
                    .background {
                        Circle().fill(palette.ink.opacity(0.06))
                    }
                    .overlay {
                        Circle().strokeBorder(palette.ink.opacity(0.10), lineWidth: 0.7)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("退出全屏模式")
            .accessibilityHint("恢复难度、战绩和玩法按钮")
            .accessibilityIdentifier("fullscreen-exit")

            VStack(alignment: .leading, spacing: 1) {
                Text(difficulty.title)
                    .font(.gameRounded(8, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(palette.secondaryInk)

                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(palette.flagDeep)
                    Text(TimeFormat.counter(game.remainingMines))
                        .font(.gameMono(16, weight: .bold))
                        .foregroundStyle(palette.ink)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.snappy(duration: 0.2), value: game.remainingMines)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("剩余地雷")
            .accessibilityValue("\(game.remainingMines) 颗")

            Spacer(minLength: 6)

            ResetFaceButton(status: game.status, action: onReset, diameter: 38)

            Spacer(minLength: 6)

            CompactTimer(game: game)

            Button(action: onToggleFlagMode) {
                HStack(spacing: 4) {
                    Image(systemName: isFlagMode ? "flag.fill" : "flag")
                        .font(.system(size: 10, weight: .bold))
                    Text("标记")
                        .font(.gameRounded(10, weight: .bold))
                }
                .foregroundStyle(isFlagMode ? palette.onAccent : palette.secondaryInk)
                .padding(.horizontal, 10)
                .frame(height: 33)
                .contentShape(.capsule)
                .background {
                    Capsule(style: .continuous)
                        .fill(isFlagMode ? AnyShapeStyle(palette.accentGradient) : AnyShapeStyle(palette.ink.opacity(0.05)))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(isFlagMode ? Color.clear : palette.ink.opacity(0.11), lineWidth: 0.7)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("标记模式")
            .accessibilityValue(isFlagMode ? "已开启" : "已关闭")
            .accessibilityHint("切换轻点方格时的操作")
            .accessibilityIdentifier("fullscreen-flag-mode")
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
        .glassPanel(cornerRadius: 20)
    }
}

struct CompactTimer: View {
    @Environment(\.gamePalette) private var palette
    let game: MinesweeperGame

    var body: some View {
        Group {
            if game.status == .playing {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    timerLabel(seconds: game.elapsedSeconds(at: context.date))
                }
            } else {
                timerLabel(seconds: game.finishedSeconds ?? 0)
            }
        }
    }

    private func timerLabel(seconds: Int) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("用时")
                .font(.gameRounded(8, weight: .bold))
                .tracking(1)
                .foregroundStyle(palette.secondaryInk)

            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(palette.mint.opacity(0.9))
                Text(TimeFormat.clock(seconds))
                    .font(.gameMono(16, weight: .bold))
                    .foregroundStyle(palette.ink)
                    .contentTransition(.numericText(countsDown: false))
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("用时")
        .accessibilityValue(TimeFormat.clock(seconds))
    }
}
