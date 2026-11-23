import Accessibility
import SwiftUI

struct BoardView: View {
    @Environment(\.gamePalette) private var palette
    let game: MinesweeperGame
    let isFlagMode: Bool
    let bestSeconds: Int?
    let result: GameResult?
    let isResultVisible: Bool
    let onPrimaryAction: (Int) -> Void
    let onSecondaryAction: (Int) -> Void
    let onReplay: () -> Void
    let onInspectBoard: () -> Void

    var showsHeader = true
    var edgeInset: CGFloat = 12
    var cardCornerRadius: CGFloat = 30
    var onEnterFullScreen: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppTheme.storageKey) private var themeRawValue = AppTheme.midnightGold.rawValue
    @State private var applicationAccessibilityEnabled = BoardAccessibilityObserver.needsGrid

    @State private var zoomScale: CGFloat = 1
    @State private var zoomResetID = UUID()

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
    }

    var body: some View {
        ZStack {
            boardContent
                .accessibilityHidden(isResultVisible)

            if isResultVisible, let result {
                GameResultOverlay(
                    result: result,
                    bestSeconds: bestSeconds,
                    onReplay: onReplay,
                    onInspectBoard: onInspectBoard
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .modifier(BoardAccessibilityObserver(isEnabled: $applicationAccessibilityEnabled))
        .background(boardSurface)
        .clipShape(cardShape)
        .overlay {
            cardShape.strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        palette.accent.opacity(0.13),
                        Color.white.opacity(0.025)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.9
            )
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.36 : 0.22), radius: 26, x: 0, y: 18)
        .overlay(alignment: .bottomTrailing) {
            if !isResultVisible {
                zoomResetButton
                    .padding(14)
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.42, bounce: 0.18), value: isResultVisible)
        .accessibilityElement(children: .contain)
    }

    private var boardContent: some View {
        VStack(spacing: 0) {
            if showsHeader {
                boardHeader
            }

            GeometryReader { proxy in
                let layout = BoardLayout(
                    configuration: game.configuration,
                    viewport: proxy.size,
                    edgeInset: edgeInset
                )
                boardViewport(layout: layout)
            }
        }
    }

    private var boardSurface: some View {
        ZStack {
            LinearGradient(
                colors: [palette.boardTop, palette.boardBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [palette.accent.opacity(0.09), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 380
            )

            RadialGradient(
                colors: [palette.mint.opacity(0.05), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 360
            )

            LinearGradient(
                colors: [Color.white.opacity(0.035), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    private var boardHeader: some View {
        VStack(spacing: 9) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(statusTint.opacity(0.18))
                        .frame(width: 11, height: 11)
                    Circle()
                        .fill(statusTint)
                        .frame(width: 5, height: 5)
                        .shadow(color: statusTint.opacity(0.8), radius: 3)
                }

                Text("雷区")
                    .font(.gameRounded(10.5, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(palette.boardText.opacity(0.92))

                Text(game.configuration.sizeLabel)
                    .font(.gameMono(9, weight: .medium))
                    .foregroundStyle(palette.boardSecondaryText.opacity(0.8))

                if game.configuration.columns > 20 {
                    HStack(spacing: 3) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 8, weight: .semibold))
                        Text("拖动 · 双指缩放")
                            .font(.gameRounded(8.5, weight: .semibold))
                    }
                    .foregroundStyle(palette.boardSecondaryText.opacity(0.72))
                }

                Spacer(minLength: 8)

                Text(statusText)
                    .font(.gameRounded(10, weight: .semibold))
                    .foregroundStyle(palette.boardSecondaryText)
                    .contentTransition(.numericText(countsDown: false))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let onEnterFullScreen {
                    Button(action: onEnterFullScreen) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(palette.boardText.opacity(0.82))
                            .frame(width: 28, height: 28)
                            .contentShape(.circle)
                            .background {
                                Circle()
                                    .fill(Color.white.opacity(0.055))
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.6)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("进入全屏模式")
                    .accessibilityHint("隐藏其他界面，放大棋盘")
                    .accessibilityIdentifier("fullscreen-button")
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.065))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [palette.accent, palette.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, proxy.size.width * game.progress))
                        .opacity(game.progress > 0 ? 1 : 0)
                }
                .animation(.snappy(duration: 0.3), value: game.progress)
            }
            .frame(height: 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .accessibilityElement(children: .contain)
    }

    private func boardViewport(layout: BoardLayout) -> some View {
        BoardZoomScrollView(
            contentSize: layout.contentSize,
            edgeInset: layout.inset,
            boardID: game.id,
            resetID: zoomResetID,
            accessibilityHint: layout.isScrollable
                ? "棋盘较大，可以拖动查看，也可以双指缩放。轻点方格翻开，长按方格插旗。"
                : "可以双指缩放棋盘。轻点方格翻开，长按方格插旗。",
            onZoomChange: { zoomScale = $0 }
        ) { renderScale in
            interactiveBoardGrid(geometry: zoomedGeometry(layout: layout, scale: renderScale))
        }
        .onChange(of: game.id) { _, _ in
            zoomScale = 1
        }
    }

    @ViewBuilder
    private var zoomResetButton: some View {
        if zoomScale > 1.01 {
            Button {
                Haptics.selection()
                zoomScale = 1
                zoomResetID = UUID()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(Int((zoomScale * 100).rounded()))%")
                        .font(.gameMono(10, weight: .bold))
                }
                .foregroundStyle(palette.boardText.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background {
                    Capsule(style: .continuous)
                        .fill(palette.boardInner.opacity(0.92))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.7)
                }
                .shadow(color: Color.black.opacity(0.24), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("重置缩放")
            .accessibilityValue("\(Int((zoomScale * 100).rounded()))%")
            .accessibilityHint("轻点恢复适应棋盘大小")
            .accessibilityIdentifier("zoom-reset")
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }

    private func zoomedGeometry(layout: BoardLayout, scale: CGFloat) -> BoardZoomGeometry {
        let tile = layout.tile * scale
        let gap = layout.gap * scale
        let columns = game.configuration.columns
        let rows = game.configuration.rows
        let size = CGSize(
            width: CGFloat(columns) * tile + CGFloat(columns - 1) * gap,
            height: CGFloat(rows) * tile + CGFloat(rows - 1) * gap
        )
        return BoardZoomGeometry(tile: tile, gap: gap, contentSize: size)
    }

    private func interactiveBoardGrid(geometry: BoardZoomGeometry) -> some View {
        let columns = game.configuration.columns
        let rows = game.configuration.rows

        return ZStack(alignment: .topLeading) {
            BoardHiddenCanvas(
                columns: columns,
                rows: rows,
                tile: geometry.tile,
                spacing: geometry.gap,
                themeToken: "\(themeRawValue)-\(colorScheme == .dark ? "dark" : "light")"
            )
            .equatable()

            BoardCanvas(
                cells: game.cells,
                configuration: game.configuration,
                tile: geometry.tile,
                spacing: geometry.gap
            )

            // iOS 27 reports when an assistive technology needs the AX tree.
            // On iOS 26, retain the grid so every accessibility service and
            // test automation can still reach the board.
            if applicationAccessibilityEnabled {
                BoardAccessibilityGrid(
                    cells: game.cells,
                    configuration: game.configuration,
                    tile: geometry.tile,
                    spacing: geometry.gap,
                    isGameActive: !game.status.isOver,
                    isFlagMode: isFlagMode,
                    onActivate: { index in handleTap(at: index) },
                    onAlternate: { index in handleLongPress(at: index) }
                )
            }

            BoardInteractionLayer(
                columns: game.configuration.columns,
                rows: game.configuration.rows,
                tileSide: geometry.tile,
                spacing: geometry.gap,
                onTap: handleTap,
                onLongPress: handleLongPress
            )
            .accessibilityHidden(true)
        }
        .frame(width: geometry.contentSize.width, height: geometry.contentSize.height)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Touch dispatch

    private func handleTap(at index: Int) {
        guard isActive, game.configuration.contains(index: index) else { return }
        let cell = game.cells[index]

        if cell.isRevealed {
            performReveal(at: index)
        } else if cell.isFlagged {
            performFlag(at: index)
        } else if isFlagMode {
            performFlag(at: index)
        } else {
            performReveal(at: index)
        }
    }

    private func handleLongPress(at index: Int) {
        guard isActive, game.configuration.contains(index: index) else { return }
        let cell = game.cells[index]

        if cell.isRevealed {
            performReveal(at: index)
        } else if cell.isFlagged {
            performFlag(at: index)
        } else if isFlagMode {
            performReveal(at: index)
        } else {
            performFlag(at: index)
        }
    }

    private func performReveal(at index: Int) {
        if isFlagMode {
            onSecondaryAction(index)
        } else {
            onPrimaryAction(index)
        }
    }

    private func performFlag(at index: Int) {
        if isFlagMode {
            onPrimaryAction(index)
        } else {
            onSecondaryAction(index)
        }
    }

    private var isActive: Bool {
        !game.status.isOver
    }

    private var statusTint: Color {
        switch game.status {
        case .ready: palette.accent
        case .playing: palette.mint
        case .won: palette.accent
        case .lost: palette.coral
        }
    }

    private var statusText: String {
        switch game.status {
        case .ready:
            "轻点开始 · 长按插旗"
        case .playing:
            "已清理 \(game.revealedSafeCount) / \(game.safeCellCount)"
        case .won:
            "全部清理完成"
        case .lost:
            "踩到地雷了"
        }
    }
}

private struct BoardAccessibilityObserver: ViewModifier {
    @Binding var isEnabled: Bool

    static var needsGrid: Bool {
        if #available(iOS 27.0, *) {
            return AccessibilitySettings.isApplicationAccessibilityEnabled
        }
        return true
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 27.0, *) {
            content.onReceive(
                NotificationCenter.default.publisher(
                    for: AccessibilitySettings.applicationAccessibilityEnabledDidChangeNotification
                )
            ) { _ in
                isEnabled = Self.needsGrid
            }
        } else {
            content
        }
    }
}

private struct BoardZoomGeometry {
    let tile: CGFloat
    let gap: CGFloat
    let contentSize: CGSize
}

private struct BoardLayout {
    let tile: CGFloat
    let gap: CGFloat
    let inset: CGFloat
    let contentSize: CGSize
    let isScrollable: Bool

    init(configuration: BoardConfiguration, viewport: CGSize, edgeInset: CGFloat) {
        let inset = edgeInset
        let gap: CGFloat = configuration.columns >= 13 ? 2 : 3
        let maximumTile: CGFloat = viewport.width > 600 ? 64 : 52
        let minimumTile: CGFloat = 20

        let usableWidth = max(40, viewport.width - inset * 2)
        let usableHeight = max(40, viewport.height - inset * 2)
        let widthFit = (usableWidth - CGFloat(configuration.columns - 1) * gap) / CGFloat(configuration.columns)
        let heightFit = (usableHeight - CGFloat(configuration.rows - 1) * gap) / CGFloat(configuration.rows)

        var side = floor(min(widthFit, heightFit, maximumTile))
        side = max(minimumTile, side)

        let contentWidth = CGFloat(configuration.columns) * side + CGFloat(configuration.columns - 1) * gap
        let contentHeight = CGFloat(configuration.rows) * side + CGFloat(configuration.rows - 1) * gap

        tile = side
        self.gap = gap
        self.inset = inset
        contentSize = CGSize(width: contentWidth, height: contentHeight)
        isScrollable = contentWidth + inset * 2 > viewport.width + 1
            || contentHeight + inset * 2 > viewport.height + 1
    }
}
