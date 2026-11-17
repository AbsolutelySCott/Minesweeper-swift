import SwiftUI
import UIKit

/// A single transparent touch layer that turns taps and long presses on the
/// board into cell indices. Keeping one gesture layer (instead of a gesture on
/// every tile) keeps large boards responsive and lets the board scroll freely.
struct BoardInteractionLayer: UIViewRepresentable {
    let columns: Int
    let rows: Int
    let tileSide: CGFloat
    let spacing: CGFloat
    let onTap: (Int) -> Void
    let onLongPress: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.isMultipleTouchEnabled = false
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.cancelsTouchesInView = false
        tap.delaysTouchesBegan = false
        tap.numberOfTouchesRequired = 1

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.34
        longPress.allowableMovement = 12
        longPress.cancelsTouchesInView = false
        longPress.delaysTouchesBegan = false
        longPress.numberOfTouchesRequired = 1

        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(longPress)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: BoardInteractionLayer
        private var longPressHandled = false
        private var resetTask: Task<Void, Never>?

        init(parent: BoardInteractionLayer) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended,
                  let index = index(at: recognizer.location(in: recognizer.view)) else {
                return
            }

            if longPressHandled {
                longPressHandled = false
                resetTask?.cancel()
                return
            }
            parent.onTap(index)
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began,
                  let index = index(at: recognizer.location(in: recognizer.view)) else {
                return
            }

            longPressHandled = true
            parent.onLongPress(index)

            resetTask?.cancel()
            resetTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                self?.longPressHandled = false
            }
        }

        private func index(at point: CGPoint?) -> Int? {
            guard let point else { return nil }

            let stride = parent.tileSide + parent.spacing
            guard stride > 0, point.x >= 0, point.y >= 0 else { return nil }

            let column = Int(point.x / stride)
            let row = Int(point.y / stride)
            guard (0..<parent.columns).contains(column),
                  (0..<parent.rows).contains(row) else {
                return nil
            }

            return row * parent.columns + column
        }
    }
}
