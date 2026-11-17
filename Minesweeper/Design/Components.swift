import SwiftUI

// MARK: - App mark

struct AppLogoMark: View {
    @Environment(\.gamePalette) private var palette
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.boardTop, palette.boardBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.32), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
                .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 6)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [palette.flag.opacity(0.26), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.48
                    )
                )
                .frame(width: size * 0.9, height: size * 0.9)

            Image(systemName: "flag.fill")
                .font(.system(size: size * 0.43, weight: .black))
                .foregroundStyle(palette.flagGradient)
                .shadow(color: Color.black.opacity(0.28), radius: 2, x: 0, y: 1.5)


        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Buttons

struct GlassIconButton: View {
    @Environment(\.gamePalette) private var palette
    let systemImage: String
    let accessibilityLabel: String
    var identifier: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(palette.ink)
                .frame(width: 42, height: 42)
                .contentShape(.circle)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier ?? "icon-button")
    }
}

struct GoldButtonStyle: ButtonStyle {
    let palette: GamePalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.gameRounded(17, weight: .bold))
            .foregroundStyle(palette.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                Capsule(style: .continuous)
                    .fill(palette.accentGradient)
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.45), lineWidth: 0.7)
            }
            .shadow(color: palette.accentDeep.opacity(0.32), radius: 16, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Small labels

struct EyebrowLabel: View {
    @Environment(\.gamePalette) private var palette
    let text: String
    var color: Color?

    var body: some View {
        Text(text.uppercased())
            .font(.gameRounded(9, weight: .bold))
            .tracking(2.2)
            .foregroundStyle(color ?? palette.secondaryInk)
    }
}

struct BestTimeBadge: View {
    @Environment(\.gamePalette) private var palette
    let seconds: Int?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(palette.accentDeep)

            Text(seconds.map { "最佳 \(TimeFormat.clock($0))" } ?? "暂无纪录")
                .font(.gameRounded(11, weight: .semibold))
                .foregroundStyle(palette.secondaryInk)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(seconds.map { "最佳成绩 \(TimeFormat.clock($0))" } ?? "暂无最佳成绩")
    }
}
