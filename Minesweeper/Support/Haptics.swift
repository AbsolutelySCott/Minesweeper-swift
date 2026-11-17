import Foundation
import UIKit

/// Small wrappers around UIKit's feedback generators. The generators are
/// created once and kept warm so the first tap of a game does not pay for
/// engine startup.
@MainActor
enum Haptics {
    enum Impact {
        case light
        case medium
        case heavy
        case soft
        case rigid

        var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: .light
            case .medium: .medium
            case .heavy: .heavy
            case .soft: .soft
            case .rigid: .rigid
            }
        }
    }

    enum Notification {
        case success
        case warning
        case error

        var feedbackType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success: .success
            case .warning: .warning
            case .error: .error
            }
        }
    }

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "minesweeper.hapticsEnabled") as? Bool ?? true
    }

    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func prepare() {
        guard isEnabled else { return }
        let generators: [UIFeedbackGenerator] = [
            lightGenerator,
            mediumGenerator,
            heavyGenerator,
            softGenerator,
            rigidGenerator,
            selectionGenerator,
            notificationGenerator
        ]
        for generator in generators {
            generator.prepare()
        }
    }

    static func impact(_ style: Impact, intensity: CGFloat = 1) {
        guard isEnabled else { return }
        let generator = generator(for: style)
        generator.impactOccurred(intensity: intensity)
        generator.prepare()
    }

    static func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    static func notify(_ type: Notification) {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(type.feedbackType)
        notificationGenerator.prepare()
    }

    private static func generator(for style: Impact) -> UIImpactFeedbackGenerator {
        switch style {
        case .light: lightGenerator
        case .medium: mediumGenerator
        case .heavy: heavyGenerator
        case .soft: softGenerator
        case .rigid: rigidGenerator
        }
    }
}
