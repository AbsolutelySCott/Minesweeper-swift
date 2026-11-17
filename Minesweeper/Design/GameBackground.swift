import SwiftUI

/// The atmospheric, slightly technical backdrop behind the game.
struct GameBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    private static let meshPoints: [SIMD2<Float>] = [
        SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0),
        SIMD2(0, 0.5), SIMD2(0.55, 0.42), SIMD2(1, 0.5),
        SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Theme.backgroundBase

                MeshGradient(
                    width: 3,
                    height: 3,
                    points: Self.meshPoints,
                    colors: meshColors
                )

                ambientGlow(in: proxy.size)

                DotField(color: colorScheme == .dark ? .white : Color(hex: 0x35465C))
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

    private var meshColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: 0x05080E), Color(hex: 0x0B1726), Color(hex: 0x060B13),
                Color(hex: 0x0D1927), Color(hex: 0x102132), Color(hex: 0x09111C),
                Color(hex: 0x070B12), Color(hex: 0x0B131B), Color(hex: 0x05080E)
            ]
        }
        return [
            Color(hex: 0xF2E2CC), Color(hex: 0xC9DDEC), Color(hex: 0xF0DDC5),
            Color(hex: 0xD8E6F1), Color(hex: 0xF5E8D3), Color(hex: 0xC7DDE8),
            Color(hex: 0xE8ECEF), Color(hex: 0xDAEAE7), Color(hex: 0xEBDAC5)
        ]
    }

    @ViewBuilder
    private func ambientGlow(in size: CGSize) -> some View {
        let goldOpacity = colorScheme == .dark ? 0.20 : 0.38
        let tealOpacity = colorScheme == .dark ? 0.16 : 0.18

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.gold.opacity(goldOpacity), .clear],
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
                        colors: [Theme.mint.opacity(tealOpacity), .clear],
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
