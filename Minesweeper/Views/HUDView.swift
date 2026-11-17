import SwiftUI

struct HUDView: View {
    @Environment(\.gamePalette) private var palette
    let game: MinesweeperGame
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            MineCounter(value: game.remainingMines)
                .frame(maxWidth: .infinity, alignment: .leading)

            divider

            ResetFaceButton(status: game.status, action: onReset)

            divider

            TimerCounter(game: game)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(minHeight: 76)
        .glassPanel(cornerRadius: 26)
        .accessibilityElement(children: .contain)
    }

    private var divider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, palette.ink.opacity(0.12), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 1, height: 34)
            .padding(.horizontal, 10)
            .accessibilityHidden(true)
    }
}

private struct MineCounter: View {
    @Environment(\.gamePalette) private var palette
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(palette.flagDeep)
                Text("剩余地雷")
                    .font(.gameRounded(9, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(palette.secondaryInk)
            }

            Text(TimeFormat.counter(value))
                .font(.gameMono(27, weight: .bold))
                .foregroundStyle(palette.ink)
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy(duration: 0.22), value: value)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("剩余地雷")
        .accessibilityValue("\(value) 颗")
    }
}

private struct TimerCounter: View {
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
        VStack(alignment: .trailing, spacing: 3) {
            HStack(spacing: 5) {
                Text("用时")
                    .font(.gameRounded(9, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(palette.secondaryInk)
                Image(systemName: "timer")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(palette.mint.opacity(0.9))
            }

            Text(TimeFormat.clock(seconds))
                .font(.gameMono(27, weight: .bold))
                .foregroundStyle(palette.ink)
                .contentTransition(.numericText(countsDown: false))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("用时")
        .accessibilityValue(TimeFormat.clock(seconds))
    }
}

struct ResetFaceButton: View {
    @Environment(\.gamePalette) private var palette
    let status: GameStatus
    let action: () -> Void
    var diameter: CGFloat = 51

    private var face: String {
        switch status {
        case .ready, .playing: "🙂"
        case .won: "😎"
        case .lost: "😵"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(face)
                .font(.system(size: diameter * 0.55))
                .frame(width: diameter, height: diameter)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [palette.boardTop, palette.boardBottom],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [palette.accent.opacity(0.7), palette.accentDeep.opacity(0.18)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: Color.black.opacity(0.28), radius: 8, x: 0, y: 5)
                }
                .contentShape(.circle)
        }
        .buttonStyle(FacePressStyle())
        .accessibilityLabel("重新开始")
        .accessibilityHint("开始一局新的扫雷")
        .accessibilityIdentifier("face-button")
    }
}

private struct FacePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }
}

struct GameFooter: View {
    @Environment(\.gamePalette) private var palette
    let bestSeconds: Int?
    let isFlagMode: Bool
    let onToggleFlagMode: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            BestTimeBadge(seconds: bestSeconds)

            Spacer(minLength: 6)

            Text(isFlagMode ? "轻点插旗 · 长按翻开" : "轻点翻开 · 长按插旗")
                .font(.gameRounded(10.5, weight: .medium))
                .foregroundStyle(palette.secondaryInk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityHidden(true)

            Spacer(minLength: 6)

            Button(action: onToggleFlagMode) {
                HStack(spacing: 6) {
                    Image(systemName: isFlagMode ? "flag.fill" : "flag")
                        .font(.system(size: 10, weight: .bold))
                    Text("标记模式")
                        .font(.gameRounded(11, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundStyle(isFlagMode ? palette.onAccent : palette.secondaryInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule(style: .continuous)
                        .fill(isFlagMode ? AnyShapeStyle(palette.accentGradient) : AnyShapeStyle(.clear))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(isFlagMode ? .clear : palette.ink.opacity(0.13), lineWidth: 0.8)
                }
                .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("标记模式")
            .accessibilityIdentifier("flag-mode-toggle")
            .accessibilityValue(isFlagMode ? "已开启，轻点方格插旗" : "已关闭，轻点方格翻开")
            .accessibilityHint("切换轻点方格时的操作")
        }
        .frame(height: 32)
    }
}
