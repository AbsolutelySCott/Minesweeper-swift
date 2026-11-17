import SwiftUI

struct GameScreen: View {
    @State private var model = GameModel()
    @State private var showsStats = false
    @State private var showsHelp = false
    @State private var isResultVisible = false
    @State private var isFullScreen = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppTheme.storageKey) private var themeRawValue = AppTheme.midnightGold.rawValue

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? .midnightGold
    }
    private var palette: GamePalette {
        GamePalette(theme: selectedTheme, scheme: colorScheme)
    }
    private var usesPhoneLandscape: Bool {
        horizontalSizeClass == .compact && verticalSizeClass == .compact
    }

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
        .environment(\.gamePalette, palette)
        .statusBarHidden(isFullScreen)
        .sheet(isPresented: $showsStats) {
            StatsSheet(model: model)
                .environment(\.gamePalette, palette)
        }
        .sheet(isPresented: $showsHelp) {
            HelpSheet()
                .environment(\.gamePalette, palette)
        }
        .task(id: resultTaskID) {
            await presentResultIfNeeded()
        }
        .tint(palette.accentDeep)
    }

    // MARK: - Layouts

    @ViewBuilder
    private var standardLayout: some View {
        if usesPhoneLandscape {
            landscapeLayout
        } else {
            portraitLayout
        }
    }

    private var portraitLayout: some View {
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

            gameBoard(
                showsHeader: true,
                edgeInset: 12,
                cornerRadius: 30,
                onEnterFullScreen: { enterFullScreen() }
            )
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

    private var landscapeLayout: some View {
        HStack(spacing: 10) {
            LandscapeSidebar(
                game: model.game,
                difficulty: model.difficulty,
                bestSeconds: model.currentBestSeconds,
                isFlagMode: model.isFlagMode,
                onSelectDifficulty: { model.selectDifficulty($0) },
                onReset: { model.startNewGame() },
                onToggleFlagMode: toggleFlagMode,
                onShowStats: { showsStats = true },
                onShowHelp: { showsHelp = true },
                onEnterFullScreen: enterFullScreen
            )

            gameBoard(
                showsHeader: false,
                edgeInset: 8,
                cornerRadius: 24,
                onEnterFullScreen: nil
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: 1100, maxHeight: .infinity)
    }

    private var fullScreenLayout: some View {
        VStack(spacing: 8) {
            FullScreenHUD(
                game: model.game,
                difficulty: model.difficulty,
                isFlagMode: model.isFlagMode,
                onExit: exitFullScreen,
                onReset: { model.startNewGame() },
                onToggleFlagMode: toggleFlagMode,
                onToggleOrientation: toggleFullScreenOrientation
            )
            .frame(maxWidth: isRegularWidth ? 760 : .infinity)

            gameBoard(
                showsHeader: false,
                edgeInset: usesPhoneLandscape ? 6 : 8,
                cornerRadius: 24,
                onEnterFullScreen: nil
            )
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

    private func gameBoard(
        showsHeader: Bool,
        edgeInset: CGFloat,
        cornerRadius: CGFloat,
        onEnterFullScreen: (() -> Void)?
    ) -> some View {
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
            showsHeader: showsHeader,
            edgeInset: edgeInset,
            cardCornerRadius: cornerRadius,
            onEnterFullScreen: onEnterFullScreen
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            AppLogoMark(size: 43)

            VStack(alignment: .leading, spacing: 0) {
                EyebrowLabel(text: "Minesweeper", color: palette.tertiaryInk)
                    .accessibilityHidden(true)

                Text("扫雷")
                    .font(.gameRounded(26, weight: .bold))
                    .foregroundStyle(palette.ink)
                    .accessibilityAddTraits(.isHeader)

                Text("\(model.difficulty.title) · \(model.difficulty.summary)")
                    .font(.gameRounded(10.5, weight: .medium))
                    .foregroundStyle(palette.secondaryInk)
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

    private func toggleFullScreenOrientation() {
        Haptics.selection()
        InterfaceOrientationController.toggleFullScreenOrientation()
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
