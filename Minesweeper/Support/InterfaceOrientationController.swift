import UIKit

/// Requests a one-shot portrait/landscape interface update from the active
/// window scene. iOS keeps the app's normal rotation behavior afterward, so the
/// physical device can still be rotated freely.
@MainActor
enum InterfaceOrientationController {
    static func toggleFullScreenOrientation() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        let target: UIInterfaceOrientationMask
        switch scene.effectiveGeometry.interfaceOrientation {
        case .landscapeLeft, .landscapeRight:
            target = .portrait
        case .portrait, .portraitUpsideDown:
            target = .landscape
        default:
            target = .landscape
        }

        scene.requestGeometryUpdate(.iOS(interfaceOrientations: target)) { _ in
            // If the system declines the request (for example while another
            // presentation owns the scene), the normal device rotation still
            // works as expected.
        }
    }
}
