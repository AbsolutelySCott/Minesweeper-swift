import SwiftUI

/// The atmospheric, slightly technical backdrop behind the game.
struct GameBackground: View {
    @Environment(\.gamePalette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    private static let meshPoints: [SIMD2<Float>] = [
        SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0),
        SIMD2(0, 0.5), SIMD2(0.55, 0.42), SIMD2(1, 0.5),
        SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                palette.backgroundBase

                MeshGradient(
                    width: 3,
                    height: 3,
                    points: Self.meshPoints,
                    colors: palette.meshColors
                )

                ambientGlow(in: proxy.size)

                DotField(color: palette.dotColor)
                    .opacity(colorScheme == .dark ? 0.055 : 0.05)
                    .blendMode(colorScheme == .dark ? .plusLighter : .normal)

                LinearGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(colorScheme == .dark ? 0.18 : 0.03)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func ambientGlow(in size: CGSize) -> some View {
        let goldOpacity = colorScheme == .dark ? 0.20 : 0.38
        let tealOpacity = colorScheme == .dark ? 0.16 : 0.18

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [palette.accent.opacity(goldOpacity), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.55
                    )
                )
                .frame(width: size.width * 1.1, height: size.width * 1.1)
                .offset(x: -size.width * 0.42, y: -size.height * 0.34)
                .blur(radius: 18)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [palette.mint.opacity(tealOpacity), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.5
                    )
                )
                .frame(width: size.width, height: size.width)
                .offset(x: size.width * 0.4, y: size.height * 0.3)
                .blur(radius: 28)
        }
    }
}

private struct DotField: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 26
            let radius: CGFloat = 0.85

            var y: CGFloat = 0
            while y <= size.height {
                var x: CGFloat = 0
                while x <= size.width {
                    let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                    x += spacing
                }
                y += spacing
            }
        }
        .blendMode(.plusLighter)
    }
}
