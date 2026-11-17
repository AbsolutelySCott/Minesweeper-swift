import SwiftUI

struct GameScreen: View {
    @State private var model = GameModel()
    @State private var showsStats = false
    @State private var showsHelp = false
    @State private var isResultVisible = false
    @State private var isFullScreen = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

    var body: some View {
        ZStack {
            GameBackground()

            if isFullScreen {
                fullScreenLayout
                    .transition(.opacity)
            } else {
                standardLayout
                    .transition(.opacity)
            }
        }
        .statusBarHidden(isFullScreen)
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

    // MARK: - Layouts

    private var standardLayout: some View {
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

            board(fullScreen: false)
                .frame(
                    maxWidth: isRegularWidth ? boardWidth : .infinity,
                    maxHeight: isRegularWidth ? boardHeight : .infinity
                )

            GameFooter(
                bestSeconds: model.currentBestSeconds,
                isFlagMode: model.isFlagMode,
                onToggleFlagMode: toggleFlagMode
            )
            .frame(maxWidth: isRegularWidth ? 700 : .infinity)
        }
        .padding(.horizontal, isRegularWidth ? 28 : 14)
        .padding(.top, 4)
        .padding(.bottom, 3)
        .frame(maxWidth: 1040, maxHeight: .infinity)
    }

    private var fullScreenLayout: some View {
        VStack(spacing: 8) {
            FullScreenHUD(
                game: model.game,
                difficulty: model.difficulty,
                isFlagMode: model.isFlagMode,
                onExit: exitFullScreen,
                onReset: { model.startNewGame() },
                onToggleFlagMode: toggleFlagMode
            )
            .frame(maxWidth: isRegularWidth ? 760 : .infinity)

            board(fullScreen: true)
                .frame(
                    maxWidth: isRegularWidth ? fullScreenBoardWidth : .infinity,
                    maxHeight: isRegularWidth ? fullScreenBoardHeight : .infinity
                )
        }
        .padding(.horizontal, isRegularWidth ? 16 : 8)
        .padding(.top, 2)
        .padding(.bottom, isRegularWidth ? 6 : 2)
        .frame(maxWidth: 1280, maxHeight: .infinity)
    }

    private func board(fullScreen: Bool) -> some View {
        BoardView(
            game: model.game,
            isFlagMode: model.isFlagMode,
            bestSeconds: model.currentBestSeconds,
            result: model.result,
            isResultVisible: isResultVisible,
            onPrimaryAction: { model.primaryTap(at: $0) },
            onSecondaryAction: { model.secondaryTap(at: $0) },
            onReplay: replay,
            onInspectBoard: inspectBoard,
            showsHeader: !fullScreen,
            edgeInset: fullScreen ? 8 : 12,
            cardCornerRadius: fullScreen ? 24 : 30,
            onEnterFullScreen: fullScreen ? nil : { enterFullScreen() }
        )
    }

    // MARK: - Header

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

    // MARK: - Actions

    private func toggleFlagMode() {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) {
            model.toggleFlagMode()
        }
    }

    private func enterFullScreen() {
        Haptics.impact(.light, intensity: 0.7)
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
            isFullScreen = true
        }
    }

    private func exitFullScreen() {
        Haptics.impact(.light, intensity: 0.7)
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
            isFullScreen = false
        }
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

    private var fullScreenBoardWidth: CGFloat {
        switch model.difficulty {
        case .beginner: 780
        case .intermediate: 900
        case .expert: 960
        }
    }

    private var fullScreenBoardHeight: CGFloat {
        switch model.difficulty {
        case .beginner: 780
        case .intermediate: 900
        case .expert: 600
        }
    }

    // MARK: - Result presentation

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
