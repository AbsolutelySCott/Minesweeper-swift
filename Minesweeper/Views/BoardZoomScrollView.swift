import SwiftUI
import UIKit

/// UIScrollView keeps the content under the moving pinch midpoint, including
/// when another pinch starts after panning. Its identity stays stable on release.
struct BoardZoomScrollView<Content: View>: UIViewControllerRepresentable {
    let contentSize: CGSize
    let edgeInset: CGFloat
    let boardID: UUID
    let resetID: UUID
    let accessibilityHint: String
    let onZoomChange: (CGFloat) -> Void
    @ViewBuilder let content: (CGFloat) -> Content

    func makeUIViewController(context: Context) -> BoardZoomController {
        BoardZoomController()
    }

    func updateUIViewController(_ controller: BoardZoomController, context: Context) {
        controller.update(
            contentSize: contentSize,
            edgeInset: edgeInset,
            boardID: boardID,
            resetID: resetID,
            accessibilityHint: accessibilityHint,
            onZoomChange: onZoomChange,
            content: { scale in
                AnyView(
                    content(scale)
                        .environment(\.gamePalette, context.environment.gamePalette)
                        .environment(\.colorScheme, context.environment.colorScheme)
                )
            }
        )
    }
}

@MainActor
final class BoardZoomController: UIViewController, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let zoomSurface = UIView()
    private let host = UIHostingController(rootView: AnyView(EmptyView()))
    private var contentSize: CGSize = .zero
    private var edgeInset: CGFloat = 0
    private var boardID: UUID?
    private var resetID: UUID?
    private var laidOutContentSize: CGSize = .zero
    private var laidOutViewport: CGSize = .zero
    private var laidOutInset: CGFloat = 0
    private var needsReset = true
    private var renderScale: CGFloat = 1
    private var makeContent: ((CGFloat) -> AnyView)?
    private var onZoomChange: ((CGFloat) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        scrollView.backgroundColor = .clear
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 3
        scrollView.bouncesZoom = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delaysContentTouches = false
        scrollView.accessibilityIdentifier = "board"
        scrollView.accessibilityLabel = "扫雷棋盘"
        view.addSubview(scrollView)
        scrollView.addSubview(zoomSurface)

        host.safeAreaRegions = []
        host.view.backgroundColor = .clear
        addChild(host)
        zoomSurface.addSubview(host.view)
        host.didMove(toParent: self)
    }

    func update(
        contentSize: CGSize,
        edgeInset: CGFloat,
        boardID: UUID,
        resetID: UUID,
        accessibilityHint: String,
        onZoomChange: @escaping (CGFloat) -> Void,
        content: @escaping (CGFloat) -> AnyView
    ) {
        loadViewIfNeeded()
        scrollView.accessibilityHint = accessibilityHint
        needsReset = needsReset || self.boardID != boardID || self.resetID != resetID
        self.contentSize = contentSize
        self.edgeInset = edgeInset
        self.boardID = boardID
        self.resetID = resetID
        self.onZoomChange = onZoomChange
        makeContent = content
        host.rootView = content(renderScale)
        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let viewport = view.bounds.size
        guard viewport.width > 0, viewport.height > 0, contentSize != .zero else { return }
        guard needsReset || viewport != laidOutViewport || contentSize != laidOutContentSize
                || edgeInset != laidOutInset else { return }

        // Preserve the visible board point if rotation changes the base layout.
        let oldCenter = zoomSurface.convert(
            CGPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY),
            from: scrollView
        )
        let oldOrigin = boardOrigin(surface: zoomSurface.bounds.size, board: laidOutContentSize)
        let anchor = CGPoint(
            x: laidOutContentSize.width > 0 ? (oldCenter.x - oldOrigin.x) / laidOutContentSize.width : 0.5,
            y: laidOutContentSize.height > 0 ? (oldCenter.y - oldOrigin.y) / laidOutContentSize.height : 0.5
        )

        scrollView.frame = view.bounds
        if needsReset {
            scrollView.setZoomScale(1, animated: false)
            renderScale = 1
            host.rootView = makeContent?(renderScale) ?? AnyView(EmptyView())
        }

        // Include the initial empty margins in the zoom surface. Dynamically
        // centering a smaller board during a pinch would move its focal point.
        let surface = CGSize(
            width: max(viewport.width, contentSize.width + 2 * edgeInset),
            height: max(viewport.height, contentSize.height + 2 * edgeInset)
        )
        let scale = scrollView.zoomScale
        zoomSurface.bounds = CGRect(origin: .zero, size: surface)
        zoomSurface.center = CGPoint(x: surface.width * scale / 2, y: surface.height * scale / 2)
        scrollView.contentSize = CGSize(width: surface.width * scale, height: surface.height * scale)
        layoutHostedBoard()

        let origin = boardOrigin(surface: surface, board: contentSize)
        let target = needsReset ? CGPoint(x: 0.5, y: 0.5) : anchor
        scrollView.contentOffset = CGPoint(
            x: min(max(0, (origin.x + target.x * contentSize.width) * scale - viewport.width / 2),
                   max(0, scrollView.contentSize.width - viewport.width)),
            y: min(max(0, (origin.y + target.y * contentSize.height) * scale - viewport.height / 2),
                   max(0, scrollView.contentSize.height - viewport.height))
        )

        laidOutViewport = viewport
        laidOutContentSize = contentSize
        laidOutInset = edgeInset
        needsReset = false
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        zoomSurface
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // Redraw the Canvas once at the final resolution. The inverse transform
        // keeps its board coordinates and the scroll offset unchanged.
        renderScale = scale
        host.rootView = makeContent?(scale) ?? AnyView(EmptyView())
        layoutHostedBoard()
        // A programmatic reset can also reach this delegate during a SwiftUI
        // update; defer the state notification until that update is complete.
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.onZoomChange?(self.scrollView.zoomScale)
        }
    }

    private func layoutHostedBoard() {
        host.view.bounds = CGRect(
            origin: .zero,
            size: CGSize(width: contentSize.width * renderScale, height: contentSize.height * renderScale)
        )
        host.view.transform = CGAffineTransform(scaleX: 1 / renderScale, y: 1 / renderScale)
        host.view.center = CGPoint(x: zoomSurface.bounds.midX, y: zoomSurface.bounds.midY)
    }

    private func boardOrigin(surface: CGSize, board: CGSize) -> CGPoint {
        CGPoint(x: (surface.width - board.width) / 2, y: (surface.height - board.height) / 2)
    }
}
