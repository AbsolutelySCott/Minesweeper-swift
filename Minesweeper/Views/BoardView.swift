import SwiftUI

struct BoardView: View {
    let game: MinesweeperGame
    let isFlagMode: Bool
    let bestSeconds: Int?
    let result: GameResult?
    let isResultVisible: Bool
    let onPrimaryAction: (Int) -> Void
    let onSecondaryAction: (Int) -> Void
    let onReplay: () -> Void
    let onInspectBoard: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
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
        .background(boardSurface)
        .clipShape(cardShape)
        .overlay {
            cardShape.strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Theme.gold.opacity(0.13),
                        Color.white.opacity(0.025)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.9
            )
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.36 : 0.22), radius: 26, x: 0, y: 18)
        .animation(reduceMotion ? nil : .spring(duration: 0.42, bounce: 0.18), value: isResultVisible)
        .accessibilityElement(children: .contain)
    }

    private var boardContent: some View {
        VStack(spacing: 0) {
            boardHeader

            GeometryReader { proxy in
                let layout = BoardLayout(
                    configuration: game.configuration,
                    viewport: proxy.size
                )
                boardViewport(layout: layout, viewport: proxy.size)
            }
        }
    }

    private var boardSurface: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.boardTop, Theme.boardBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Theme.gold.opacity(0.09), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 380
            )

            RadialGradient(
                colors: [Theme.mint.opacity(0.05), .clear],
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
                    .foregroundStyle(Theme.boardText.opacity(0.92))

                Text(game.configuration.sizeLabel)
                    .font(.gameMono(9, weight: .medium))
                    .foregroundStyle(Theme.boardSecondaryText.opacity(0.8))

                if game.configuration.columns > 20 {
                    HStack(spacing: 3) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 8, weight: .semibold))
                        Text("拖动查看")
                            .font(.gameRounded(8.5, weight: .semibold))
                    }
                    .foregroundStyle(Theme.boardSecondaryText.opacity(0.72))
                }

                Spacer(minLength: 8)

                Text(statusText)
                    .font(.gameRounded(10, weight: .semibold))
                    .foregroundStyle(Theme.boardSecondaryText)
                    .contentTransition(.numericText(countsDown: false))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.065))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.gold, Theme.mint],
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("扫雷棋盘，\(game.configuration.sizeLabel)，\(game.configuration.mineCount) 颗地雷")
        .accessibilityValue(statusText)
    }

    private func boardViewport(layout: BoardLayout, viewport: CGSize) -> some View {
        ScrollView([.horizontal, .vertical]) {
            boardGrid(layout: layout)
                .padding(layout.inset)
                .frame(
                    minWidth: viewport.width,
                    minHeight: viewport.height
                )
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDisabled(!layout.isScrollable)
        .defaultScrollAnchor(.center)
        .accessibilityIdentifier("board")
        .accessibilityLabel("扫雷棋盘")
        .accessibilityHint(
            layout.isScrollable
                ? "棋盘较大，可以拖动查看。轻点方格翻开，长按方格插旗。"
                : "轻点方格翻开，长按方格插旗。"
        )
    }

    private func boardGrid(layout: BoardLayout) -> some View {
        VStack(spacing: layout.gap) {
            ForEach(0..<game.configuration.rows, id: \.self) { row in
                HStack(spacing: layout.gap) {
                    ForEach(0..<game.configuration.columns, id: \.self) { column in
                        let index = game.configuration.index(row: row, column: column)

                        TileView(
                            cell: game.cells[index],
                            row: row,
                            column: column,
                            side: layout.tile,
                            isGameActive: !game.status.isOver,
                            isFlagMode: isFlagMode,
                            onPrimaryAction: { onPrimaryAction(index) },
                            onSecondaryAction: { onSecondaryAction(index) }
                        )
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var statusTint: Color {
        switch game.status {
        case .ready: Theme.gold
        case .playing: Theme.mint
        case .won: Theme.gold
        case .lost: Theme.coral
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

private struct BoardLayout {
    let tile: CGFloat
    let gap: CGFloat
    let inset: CGFloat
    let isScrollable: Bool

    init(configuration: BoardConfiguration, viewport: CGSize) {
        let inset: CGFloat = 12
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
        isScrollable = contentWidth + inset * 2 > viewport.width + 1
            || contentHeight + inset * 2 > viewport.height + 1
    }
}
