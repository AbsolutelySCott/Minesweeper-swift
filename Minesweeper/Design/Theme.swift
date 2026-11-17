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

// MARK: - Theme

enum Theme {
    // Signature colors.
    static let gold = Color(hex: 0xF3C35B)
    static let goldDeep = Color(hex: 0xD99A2C)
    static let goldHighlight = Color(hex: 0xFFE5A5)
    static let mint = Color(hex: 0x6FE3CF)
    static let coral = Color(hex: 0xFF786C)
    static let sky = Color(hex: 0x7DBBFF)

    // Text on ordinary surfaces.
    static let ink = Color(light: 0x17212F, dark: 0xF6F1E8)
    static let secondaryInk = Color(light: 0x5C697B, dark: 0x9BA8B9)
    static let tertiaryInk = Color(light: 0x6D7A8B, dark: 0x7E8B9D)

    // The game board stays deep and tactile in both appearances.
    static let boardTop = Color(hex: 0x172131)
    static let boardBottom = Color(hex: 0x090E17)
    static let boardInner = Color(hex: 0x0B121C)
    static let boardStroke = Color.white.opacity(0.10)
    static let boardText = Color(hex: 0xF4F0E7)
    static let boardSecondaryText = Color(hex: 0x93A2B7)

    static let hiddenTop = Color(hex: 0x3D4B62)
    static let hiddenBottom = Color(hex: 0x273245)
    static let hiddenStroke = Color(hex: 0x687B97)
    static let revealedTop = Color(hex: 0x192434)
    static let revealedBottom = Color(hex: 0x101924)
    static let revealedStroke = Color.white.opacity(0.07)

    static let danger = Color(hex: 0xFF7167)
    static let dangerDeep = Color(hex: 0x9D2727)

    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xFFDD86), Color(hex: 0xF0B440), Color(hex: 0xD99727)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassStroke = LinearGradient(
        colors: [Color.white.opacity(0.32), Color.white.opacity(0.04)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func number(_ count: Int) -> Color {
        switch count {
        case 1: Color(hex: 0x7FBDFF)
        case 2: Color(hex: 0x70DFB1)
        case 3: Color(hex: 0xFF8D82)
        case 4: Color(hex: 0xC4AAFF)
        case 5: Color(hex: 0xFFD37A)
        case 6: Color(hex: 0x6FE3D9)
        case 7: Color(hex: 0xFFA4CD)
        default: Color(hex: 0xE7EDF6)
        }
    }

    static var backgroundBase: Color {
        Color(light: 0xF2EDE4, dark: 0x05080E)
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

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(light: 0xFFFBF3, dark: 0x0B111A))
                            .opacity(colorScheme == .dark ? 0.12 : 0.46)
                    }
                    .overlay {
                        if let tint {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(colorScheme == .dark ? 0.10 : 0.08))
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark
                            ? AnyShapeStyle(Theme.glassStroke)
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.85), Theme.ink.opacity(0.055)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            ),
                        lineWidth: 0.8
                    )
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.11),
                radius: colorScheme == .dark ? 22 : 18,
                x: 0,
                y: colorScheme == .dark ? 12 : 9
            )
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 24, tint: Color? = nil) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius, tint: tint))
    }
}
