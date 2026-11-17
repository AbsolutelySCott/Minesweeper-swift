import Foundation
import UIKit

/// Small wrappers around UIKit's feedback generators.
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

    static func impact(_ style: Impact, intensity: CGFloat = 1) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style.feedbackStyle)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    static func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    static func notify(_ type: Notification) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type.feedbackType)
    }
}
