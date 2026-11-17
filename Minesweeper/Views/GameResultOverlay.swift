import SwiftUI
import UIKit

struct GameResultOverlay: View {
    let result: GameResult
    let bestSeconds: Int?
    let onReplay: () -> Void
    let onInspectBoard: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var titleIsFocused: Bool
    @State private var appeared = false

    private var tint: Color {
        result.won ? Theme.gold : Theme.coral
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            Rectangle()
                .fill(Color(hex: 0x040811).opacity(0.62))

            card
                .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.46, bounce: 0.24)) {
                appeared = true
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                titleIsFocused = true
            }
        }
    }

    private var card: some View {
        VStack(spacing: 17) {
            resultIcon

            VStack(spacing: 6) {
                Text(result.won ? "排雷成功" : "踩到地雷了")
                    .font(.gameRounded(26, weight: .bold))
                    .foregroundStyle(Theme.boardText)
                    .accessibilityFocused($titleIsFocused)
                    .accessibilityAddTraits(.isHeader)

                Text(result.won ? "整片雷区已经安全了" : "别泄气，再试一次")
                    .font(.gameRounded(12.5, weight: .medium))
                    .foregroundStyle(Theme.boardSecondaryText)
                    .multilineTextAlignment(.center)
            }

            if result.won && result.isNewBest {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .bold))
                    Text("新纪录 · \(result.difficulty.title)")
                        .font(.gameRounded(10.5, weight: .bold))
                }
                .foregroundStyle(Color(hex: 0x2B1C06))
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Capsule(style: .continuous).fill(Theme.goldGradient))
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .accessibilityLabel("新的最佳成绩")
            }

            HStack(spacing: 10) {
                metric(title: "用时", value: TimeFormat.clock(result.seconds), icon: "timer")
                metric(
                    title: "最佳",
                    value: displayBestSeconds.map(TimeFormat.clock) ?? "—",
                    icon: "trophy.fill"
                )
            }

            VStack(spacing: 9) {
                Button(action: onReplay) {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .bold))
                        Text("再来一局")
                    }
                }
                .buttonStyle(GoldButtonStyle())
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("result-replay")

                Button(action: onInspectBoard) {
                    HStack(spacing: 7) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("查看棋盘")
                            .font(.gameRounded(13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.boardText.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.055))
                    }
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(0.11), lineWidth: 0.8)
                    }
                }
                .buttonStyle(FadeButtonStyle())
                .accessibilityIdentifier("result-inspect")
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 23)
        .frame(maxWidth: 330)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1A2638), Color(hex: 0x0A111C)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RadialGradient(
                        colors: [tint.opacity(0.13), .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 190
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), tint.opacity(0.14), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        }
        .shadow(color: Color.black.opacity(0.5), radius: 32, x: 0, y: 20)
        .scaleEffect(appeared ? 1 : 0.94)
        .opacity(appeared ? 1 : 0)
    }

    private var displayBestSeconds: Int? {
        if let bestSeconds { return bestSeconds }
        return result.won && result.isNewBest ? result.seconds : nil
    }

    private var resultIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.26), tint.opacity(0.02)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 54
                    )
                )
                .frame(width: 98, height: 98)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x2A3A51), Color(hex: 0x101723)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 66, height: 66)
                .overlay {
                    Circle()
                        .strokeBorder(tint.opacity(0.42), lineWidth: 1)
                }
                .shadow(color: tint.opacity(0.22), radius: 14, x: 0, y: 7)

            Image(systemName: result.won ? "trophy.fill" : "burst.fill")
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(tint)
                .symbolEffect(.bounce, value: appeared)

            sparkles
        }
        .frame(height: 98)
        .accessibilityHidden(true)
    }

    private var sparkles: some View {
        ZStack {
            sparkle(angle: -58, distance: 39, size: 5)
            sparkle(angle: -20, distance: 43, size: 3.5)
            sparkle(angle: 26, distance: 40, size: 4.5)
            sparkle(angle: 62, distance: 44, size: 3)
            sparkle(angle: -100, distance: 41, size: 3)
        }
        .foregroundStyle(tint.opacity(result.won ? 0.75 : 0.35))
    }

    private func sparkle(angle: Double, distance: CGFloat, size: CGFloat) -> some View {
        Circle()
            .frame(width: size, height: size)
            .offset(
                x: cos(angle * .pi / 180) * distance,
                y: sin(angle * .pi / 180) * distance
            )
    }

    private func metric(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(tint.opacity(0.8))
                Text(title)
                    .font(.gameRounded(9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.boardSecondaryText)
            }

            Text(value)
                .font(.gameMono(19, weight: .bold))
                .foregroundStyle(Theme.boardText)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.045))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

private struct FadeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.65 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.14), value: configuration.isPressed)
    }
}
