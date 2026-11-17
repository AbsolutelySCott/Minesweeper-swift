import SwiftUI

struct GameScreen: View {
    @State private var model = GameModel()
    @State private var showsStats = false
    @State private var showsHelp = false
    @State private var isResultVisible = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

    var body: some View {
        ZStack {
            GameBackground()

            VStack(spacing: isRegularWidth ? 15 : 11) {
                header
                    .frame(maxWidth: isRegularWidth ? 700 : .infinity)

                DifficultySelector(selection: model.difficulty) { difficulty in
                    model.selectDifficulty(difficulty)
                }
                .frame(maxWidth: isRegularWidth ? 700 : .infinity)

                HUDView(game: model.game) {
                    model.startNewGame()
                }
                .frame(maxWidth: isRegularWidth ? 700 : .infinity)

                BoardView(
                    game: model.game,
                    isFlagMode: model.isFlagMode,
                    bestSeconds: model.currentBestSeconds,
                    result: model.result,
                    isResultVisible: isResultVisible,
                    onPrimaryAction: { model.primaryTap(at: $0) },
                    onSecondaryAction: { model.secondaryTap(at: $0) },
                    onReplay: replay,
                    onInspectBoard: inspectBoard
                )
                .frame(
                    maxWidth: isRegularWidth ? boardWidth : .infinity,
                    maxHeight: isRegularWidth ? boardHeight : .infinity
                )

                GameFooter(
                    bestSeconds: model.currentBestSeconds,
                    isFlagMode: model.isFlagMode,
                    onToggleFlagMode: {
                        withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) {
                            model.toggleFlagMode()
                        }
                    }
                )
                .frame(maxWidth: isRegularWidth ? 700 : .infinity)
            }
            .padding(.horizontal, isRegularWidth ? 28 : 14)
            .padding(.top, 4)
            .padding(.bottom, 3)
            .frame(maxWidth: 1040, maxHeight: .infinity)
        }
        .sheet(isPresented: $showsStats) {
            StatsSheet(model: model)
        }
        .sheet(isPresented: $showsHelp) {
            HelpSheet()
        }
        .task(id: resultTaskID) {
            await presentResultIfNeeded()
        }
        .tint(Theme.goldDeep)
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppLogoMark(size: 43)

            VStack(alignment: .leading, spacing: 0) {
                EyebrowLabel(text: "Minesweeper", color: Theme.tertiaryInk)
                    .accessibilityHidden(true)

                Text("扫雷")
                    .font(.gameRounded(26, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)

                Text("\(model.difficulty.title) · \(model.difficulty.summary)")
                    .font(.gameRounded(10.5, weight: .medium))
                    .foregroundStyle(Theme.secondaryInk)
                    .padding(.top, 1)
                    .contentTransition(.opacity)
            }

            Spacer(minLength: 6)

            GlassIconButton(
                systemImage: "chart.bar.xaxis",
                accessibilityLabel: "战绩",
                identifier: "stats-button"
            ) {
                showsStats = true
            }

            GlassIconButton(
                systemImage: "questionmark",
                accessibilityLabel: "玩法",
                identifier: "help-button"
            ) {
                showsHelp = true
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var boardWidth: CGFloat {
        switch model.difficulty {
        case .beginner, .intermediate: 700
        case .expert: 960
        }
    }

    private var boardHeight: CGFloat {
        switch model.difficulty {
        case .beginner: 700
        case .intermediate: 760
        case .expert: 620
        }
    }

    private var resultTaskID: String {
        guard let result = model.result else { return "no-result-\(model.game.id.uuidString)" }
        return [
            result.difficulty.rawValue,
            result.won ? "win" : "loss",
            "\(result.seconds)",
            result.isNewBest ? "best" : "not-best",
            model.game.id.uuidString
        ].joined(separator: "-")
    }

    @MainActor
    private func presentResultIfNeeded() async {
        guard let result = model.result else {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                isResultVisible = false
            }
            return
        }

        isResultVisible = false
        try? await Task.sleep(for: .milliseconds(480))
        guard !Task.isCancelled, model.result == result else { return }

        withAnimation(reduceMotion ? nil : .spring(duration: 0.42, bounce: 0.16)) {
            isResultVisible = true
        }
    }

    private func replay() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.16)) {
            isResultVisible = false
        }
        model.startNewGame()
    }

    private func inspectBoard() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            isResultVisible = false
        }
    }
}

#Preview("Game") {
    GameScreen()
}
