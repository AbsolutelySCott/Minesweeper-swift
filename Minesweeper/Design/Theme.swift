import SwiftUI
import UIKit

// MARK: - Color helpers

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// A color that resolves differently in light and dark appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Themes

enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case midnightGold
    case creamGreen

    static let storageKey = "minesweeper.theme"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midnightGold: "午夜金"
        case .creamGreen: "奶油绿"
        }
    }

    var subtitle: String {
        switch self {
        case .midnightGold: "深色游戏台 · 金色点缀"
        case .creamGreen: "奶油底色 · 鼠尾草绿"
        }
    }
}

// MARK: - Palette

/// Every themeable color used by the game. The root screen resolves the active
/// `AppTheme` and injects a palette into the environment, so switching themes
/// updates the whole interface without recreating the game.
struct GamePalette {
    let theme: AppTheme
    let scheme: ColorScheme

    let ink: Color
    let secondaryInk: Color
    let tertiaryInk: Color

    let accent: Color
    let accentDeep: Color
    let accentHighlight: Color
    let onAccent: Color

    let flag: Color
    let flagDeep: Color
    let flagHighlight: Color
    let onFlag: Color

    let mint: Color
    let sky: Color
    let coral: Color
    let danger: Color
    let dangerDeep: Color

    let boardTop: Color
    let boardBottom: Color
    let boardInner: Color
    let boardStroke: Color
    let boardText: Color
    let boardSecondaryText: Color

    let hiddenTop: Color
    let hiddenBottom: Color
    let hiddenStroke: Color
    let revealedTop: Color
    let revealedBottom: Color
    let revealedStroke: Color

    let backgroundBase: Color
    let dotColor: Color
    let meshColors: [Color]

    private let numberPalette: [Color]

    init(theme: AppTheme, scheme: ColorScheme) {
        self.theme = theme
        self.scheme = scheme
        let isDark = scheme == .dark

        switch theme {
        case .midnightGold:
            ink = Color(hex: isDark ? 0xF6F1E8 : 0x17212F)
            secondaryInk = Color(hex: isDark ? 0x9BA8B9 : 0x5C697B)
            tertiaryInk = Color(hex: isDark ? 0x7E8B9D : 0x6D7A8B)

            accent = Color(hex: 0xF3C35B)
            accentDeep = Color(hex: 0xD99A2C)
            accentHighlight = Color(hex: 0xFFE5A5)
            onAccent = Color(hex: 0x24190A)

            flag = accent
            flagDeep = accentDeep
            flagHighlight = accentHighlight
            onFlag = onAccent

            mint = Color(hex: 0x6FE3CF)
            sky = Color(hex: 0x7DBBFF)
            coral = Color(hex: 0xFF786C)
            danger = Color(hex: 0xFF7167)
            dangerDeep = Color(hex: 0x9D2727)

            boardTop = Color(hex: 0x172131)
            boardBottom = Color(hex: 0x090E17)
            boardInner = Color(hex: 0x0B121C)
            boardStroke = Color.white.opacity(0.10)
            boardText = Color(hex: 0xF4F0E7)
            boardSecondaryText = Color(hex: 0x93A2B7)

            hiddenTop = Color(hex: 0x3D4B62)
            hiddenBottom = Color(hex: 0x273245)
            hiddenStroke = Color(hex: 0x687B97)
            revealedTop = Color(hex: 0x192434)
            revealedBottom = Color(hex: 0x101924)
            revealedStroke = Color.white.opacity(0.07)

            backgroundBase = Color(hex: isDark ? 0x05080E : 0xF2EDE4)
            dotColor = isDark ? Color.white : Color(hex: 0x35465C)
            meshColors = isDark
                ? [
                    Color(hex: 0x05080E), Color(hex: 0x0B1726), Color(hex: 0x060B13),
                    Color(hex: 0x0D1927), Color(hex: 0x102132), Color(hex: 0x09111C),
                    Color(hex: 0x070B12), Color(hex: 0x0B131B), Color(hex: 0x05080E)
                ]
                : [
                    Color(hex: 0xF2E2CC), Color(hex: 0xC9DDEC), Color(hex: 0xF0DDC5),
                    Color(hex: 0xD8E6F1), Color(hex: 0xF5E8D3), Color(hex: 0xC7DDE8),
                    Color(hex: 0xE8ECEF), Color(hex: 0xDAEAE7), Color(hex: 0xEBDAC5)
                ]

            numberPalette = [
                Color(hex: 0x7FBDFF),
                Color(hex: 0x70DFB1),
                Color(hex: 0xFF8D82),
                Color(hex: 0xC4AAFF),
                Color(hex: 0xFFD37A),
                Color(hex: 0x6FE3D9),
                Color(hex: 0xFFA4CD),
                Color(hex: 0xE7EDF6)
            ]

        case .creamGreen:
            ink = Color(hex: isDark ? 0xF4EFE1 : 0x223026)
            secondaryInk = Color(hex: isDark ? 0xA9B6A4 : 0x5F6F61)
            tertiaryInk = Color(hex: isDark ? 0x7B8C7C : 0x819083)

            accent = Color(hex: isDark ? 0xA9C79B : 0x5F7D57)
            accentDeep = Color(hex: isDark ? 0x6E9365 : 0x3F5C3B)
            accentHighlight = Color(hex: isDark ? 0xDFECD4 : 0xCFE0C1)
            onAccent = Color(hex: isDark ? 0x16220F : 0x1E2A1B)

            flag = Color(hex: isDark ? 0xE8AB7E : 0xD99366)
            flagDeep = Color(hex: isDark ? 0xB36D45 : 0xA75E3A)
            flagHighlight = Color(hex: isDark ? 0xFFDDC0 : 0xF6D2B4)
            onFlag = Color(hex: 0x2B170C)

            mint = Color(hex: isDark ? 0x9CCCB3 : 0x5F8C77)
            sky = Color(hex: isDark ? 0xA9CBE3 : 0x7C9DB5)
            coral = Color(hex: isDark ? 0xF2A68F : 0xDF9279)
            danger = Color(hex: isDark ? 0xFF8D7E : 0xD77162)
            dangerDeep = Color(hex: 0x8D342C)

            boardTop = Color(hex: isDark ? 0x101A13 : 0x1B2A20)
            boardBottom = Color(hex: isDark ? 0x050906 : 0x090F0B)
            boardInner = Color(hex: isDark ? 0x0C140E : 0x101A13)
            boardStroke = Color.white.opacity(0.10)
            boardText = Color(hex: 0xF6F1E3)
            boardSecondaryText = Color(hex: isDark ? 0x99A995 : 0xA9B7A0)

            hiddenTop = Color(hex: isDark ? 0x455A49 : 0x536B57)
            hiddenBottom = Color(hex: isDark ? 0x2C3A30 : 0x3A4C3D)
            hiddenStroke = Color(hex: 0x83987F)
            revealedTop = Color(hex: isDark ? 0x1A281E : 0x233428)
            revealedBottom = Color(hex: isDark ? 0x111B15 : 0x18241B)
            revealedStroke = Color.white.opacity(0.06)

            backgroundBase = Color(hex: isDark ? 0x080D09 : 0xF4EDDF)
            dotColor = isDark ? Color.white : Color(hex: 0x526456)
            meshColors = isDark
                ? [
                    Color(hex: 0x070C08), Color(hex: 0x0E1A12), Color(hex: 0x0C0F09),
                    Color(hex: 0x132117), Color(hex: 0x16261B), Color(hex: 0x0D1911),
                    Color(hex: 0x090F0A), Color(hex: 0x101B13), Color(hex: 0x070C08)
                ]
                : [
                    Color(hex: 0xF7F0DF), Color(hex: 0xDFEADB), Color(hex: 0xF3E4D0),
                    Color(hex: 0xD9E7D7), Color(hex: 0xF8EEDC), Color(hex: 0xD7E8DF),
                    Color(hex: 0xEFE9DB), Color(hex: 0xE1EDE1), Color(hex: 0xF3E7D5)
                ]

            numberPalette = [
                Color(hex: 0x9EC4E0),
                Color(hex: 0x8BCB9D),
                Color(hex: 0xEFA58A),
                Color(hex: 0xC7B7E2),
                Color(hex: 0xE8CF8E),
                Color(hex: 0x91D4C3),
                Color(hex: 0xE9B4C8),
                Color(hex: 0xF7F1E4)
            ]
        }
    }

    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentHighlight, accent, accentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var flagGradient: LinearGradient {
        LinearGradient(
            colors: [flagHighlight, flag, flagDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var glassStroke: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.32), Color.white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func number(_ count: Int) -> Color {
        guard (1...8).contains(count) else { return numberPalette[7] }
        return numberPalette[count - 1]
    }
}

private struct GamePaletteKey: EnvironmentKey {
    static let defaultValue = GamePalette(theme: .midnightGold, scheme: .dark)
}

extension EnvironmentValues {
    var gamePalette: GamePalette {
        get { self[GamePaletteKey.self] }
        set { self[GamePaletteKey.self] = newValue }
    }
}

// MARK: - Typography

extension Font {
    static func gameRounded(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func gameMono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Reusable surface styling

struct GlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var tint: Color?

    @Environment(\.gamePalette) private var palette

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(palette.theme == .creamGreen
                                  ? Color(hex: palette.scheme == .dark ? 0x101A12 : 0xFFFBF2)
                                  : Color(hex: palette.scheme == .dark ? 0x0B111A : 0xFFFBF3))
                            .opacity(palette.scheme == .dark ? 0.12 : 0.46)
                    }
                    .overlay {
                        if let tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(palette.scheme == .dark ? 0.10 : 0.08))
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        palette.scheme == .dark
                            ? AnyShapeStyle(palette.glassStroke)
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.85), palette.ink.opacity(0.055)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            ),
                        lineWidth: 0.8
                    )
            }
            .shadow(
                color: Color.black.opacity(palette.scheme == .dark ? 0.18 : 0.11),
                radius: palette.scheme == .dark ? 22 : 18,
                x: 0,
                y: palette.scheme == .dark ? 12 : 9
            )
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 24, tint: Color? = nil) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius, tint: tint))
    }
}
