import UIKit

/// Requests a one-shot clockwise portrait/landscape interface update from the active
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
            // Requesting landscapeRight rotates the content clockwise from
            // portrait, which matches the app's previous natural rotation.
            target = .landscapeRight
        default:
            target = .landscapeRight
        }

        scene.requestGeometryUpdate(.iOS(interfaceOrientations: target)) { _ in
            // If the system declines the request (for example while another
            // presentation owns the scene), the normal device rotation still
            // works as expected.
        }
    }
}
