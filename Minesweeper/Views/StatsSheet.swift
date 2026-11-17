import SwiftUI

struct StatsSheet: View {
    @Environment(\.gamePalette) private var palette
    let model: GameModel

    @AppStorage("minesweeper.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage(AppTheme.storageKey) private var themeRawValue = AppTheme.midnightGold.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @State private var isConfirmingReset = false

    private var stats: PlayerStats { model.stats }
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? .midnightGold
    }

    var body: some View {
        SheetScaffold(title: "战绩", subtitle: "每一次排雷，都值得记录") {
            VStack(spacing: 18) {
                summaryCard
                themeCard
                recordsCard
                settingsCard
                aboutFooter
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .onChange(of: hapticsEnabled) { _, enabled in
            if enabled {
                Haptics.prepare()
                Haptics.selection()
            }
        }
        .alert("清空所有战绩？", isPresented: $isConfirmingReset) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                model.resetStats()
            }
        } message: {
            Text("所有难度的最佳时间和胜率都会被删除，此操作无法撤销。")
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(spacing: 22) {
            winRateRing

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stats.totalGames == 0 ? "等待第一局" : "保持冷静，继续排雷")
                        .font(.gameRounded(16, weight: .bold))
                        .foregroundStyle(palette.ink)
                    Text(stats.totalGames == 0 ? "完成一局游戏后，这里会记录你的表现。" : "你已累计完成 \(stats.totalGames) 局游戏。")
                        .font(.gameRounded(11.5, weight: .regular))
                        .foregroundStyle(palette.secondaryInk)
                        .lineSpacing(2)
                }

                HStack(spacing: 20) {
                    summaryMetric(value: "\(stats.totalWins)", label: "胜利局数")
                    summaryMetric(value: "\(stats.totalGames - stats.totalWins)", label: "失败局数")
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .glassPanel(cornerRadius: 26)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("总战绩，\(stats.totalGames) 局，胜利 \(stats.totalWins) 局，胜率 \(winRateText)")
    }

    private var winRateRing: some View {
        ZStack {
            Circle()
                .stroke(palette.ink.opacity(0.08), lineWidth: 7)

            Circle()
                .trim(from: 0, to: max(0.001, stats.winRate))
                .stroke(
                    palette.accentGradient,
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(stats.winRate > 0 ? 1 : 0)
                .animation(.spring(duration: 0.6, bounce: 0.15), value: stats.winRate)

            VStack(spacing: 1) {
                Text(winRateText)
                    .font(.gameMono(23, weight: .bold))
                    .foregroundStyle(palette.ink)
                    .contentTransition(.numericText())
                Text("胜率")
                    .font(.gameRounded(8.5, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(palette.tertiaryInk)
            }
        }
        .frame(width: 93, height: 93)
        .accessibilityHidden(true)
    }

    private var winRateText: String {
        guard stats.totalGames > 0 else { return "—" }
        return "\(Int((stats.winRate * 100).rounded()))%"
    }

    private func summaryMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.gameMono(16, weight: .bold))
                .foregroundStyle(palette.ink)
            Text(label)
                .font(.gameRounded(9, weight: .medium))
                .foregroundStyle(palette.tertiaryInk)
        }
    }

    // MARK: - Theme

    private var themeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.accentDeep)
                Text("外观主题")
                    .font(.gameRounded(12, weight: .bold))
                    .foregroundStyle(palette.ink)
                Spacer()
                Text("即时切换")
                    .font(.gameRounded(9, weight: .medium))
                    .foregroundStyle(palette.tertiaryInk)
            }

            HStack(spacing: 9) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeOptionCard(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        colorScheme: colorScheme
                    ) {
                        Haptics.selection()
                        withAnimation(.snappy(duration: 0.22)) {
                            themeRawValue = theme.rawValue
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassPanel(cornerRadius: 26)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Records

    private var recordsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("难度纪录")
                    .font(.gameRounded(11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(palette.secondaryInk)
                Spacer()
                Text("最佳 / 胜局 / 总局")
                    .font(.gameRounded(9, weight: .medium))
                    .foregroundStyle(palette.tertiaryInk)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 4)

            ForEach(Difficulty.allCases) { difficulty in
                let record = stats.record(for: difficulty)
                DifficultyRecordRow(difficulty: difficulty, record: record)

                if difficulty != Difficulty.allCases.last {
                    Rectangle()
                        .fill(palette.ink.opacity(0.06))
                        .frame(height: 0.7)
                        .padding(.leading, 18)
                }
            }
        }
        .padding(.bottom, 6)
        .glassPanel(cornerRadius: 26)
    }

    // MARK: - Settings

    private var settingsCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(palette.accentDeep)
                    .frame(width: 30, height: 30)
                    .background(palette.accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("触感反馈")
                        .font(.gameRounded(13, weight: .semibold))
                        .foregroundStyle(palette.ink)
                    Text("翻格、插旗和结束时提供细微震动")
                        .font(.gameRounded(10, weight: .regular))
                        .foregroundStyle(palette.tertiaryInk)
                }

                Spacer()

                Toggle("触感反馈", isOn: $hapticsEnabled)
                    .labelsHidden()
                    .tint(palette.accentDeep)
                    .accessibilityHint("开启或关闭游戏震动")
            }
            .padding(16)

            Rectangle()
                .fill(palette.ink.opacity(0.06))
                .frame(height: 0.7)
                .padding(.leading, 58)

            Button {
                isConfirmingReset = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(palette.coral)
                        .frame(width: 30, height: 30)
                        .background(palette.coral.opacity(0.09), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Text("重置所有战绩")
                        .font(.gameRounded(13, weight: .semibold))
                        .foregroundStyle(palette.ink)

                    Spacer()

                    Text(stats.totalGames == 0 ? "暂无数据" : "\(stats.totalGames) 局")
                        .font(.gameRounded(10, weight: .medium))
                        .foregroundStyle(palette.tertiaryInk)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(SettingsRowButtonStyle())
            .disabled(stats.totalGames == 0)
            .opacity(stats.totalGames == 0 ? 0.55 : 1)
            .accessibilityHint(stats.totalGames == 0 ? "暂无可重置的战绩" : "会清空所有难度的记录")
        }
        .glassPanel(cornerRadius: 26)
    }

    private var aboutFooter: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(palette.flagDeep)
                Text("扫雷")
                    .font(.gameRounded(11, weight: .bold))
                    .foregroundStyle(palette.secondaryInk)
            }
            Text("版本 \(version) · 为 iOS 27.2 打造")
                .font(.gameRounded(9.5, weight: .medium))
                .foregroundStyle(palette.tertiaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }

    private var version: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(shortVersion) (\(build))"
    }
}

private struct ThemeOptionCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    private var palette: GamePalette {
        GamePalette(theme: theme, scheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [palette.backgroundBase, palette.meshColors[1], palette.meshColors[4]],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    HStack(spacing: 5) {
                        miniTile(hidden: true)
                        miniTile(hidden: false)
                        Image(systemName: "flag.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(palette.flagGradient)
                            .frame(width: 22, height: 22)
                            .background(palette.hiddenTop, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                }
                .frame(height: 48)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.6)
                }

                HStack(spacing: 4) {
                    Text(theme.title)
                        .font(.gameRounded(11, weight: .bold))
                        .foregroundStyle(palette.ink)
                    Spacer(minLength: 2)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(palette.accentDeep)
                    }
                }

                Text(theme.subtitle)
                    .font(.gameRounded(8.5, weight: .medium))
                    .foregroundStyle(palette.tertiaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(9)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? palette.accent.opacity(0.10) : palette.ink.opacity(0.025))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? palette.accent.opacity(0.7) : palette.ink.opacity(0.08),
                        lineWidth: isSelected ? 1.2 : 0.7
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.title)主题")
        .accessibilityHint(theme.subtitle)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("theme-\(theme.rawValue)")
    }

    private func miniTile(hidden: Bool) -> some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(hidden ? palette.hiddenTop : palette.revealedTop)
            .frame(width: 22, height: 22)
            .overlay {
                if !hidden {
                    Text("1")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(palette.number(1))
                }
            }
    }
}

private struct DifficultyRecordRow: View {
    @Environment(\.gamePalette) private var palette
    let difficulty: Difficulty
    let record: PlayerStats.Record

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
                .frame(width: 18, height: 18)
                .background(dotColor.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(difficulty.title)
                    .font(.gameRounded(13, weight: .bold))
                    .foregroundStyle(palette.ink)
                Text(difficulty.summary)
                    .font(.gameMono(9, weight: .medium))
                    .foregroundStyle(palette.tertiaryInk)
            }

            Spacer(minLength: 6)

            Text(record.bestSeconds.map(TimeFormat.clock) ?? "—")
                .font(.gameMono(12.5, weight: .bold))
                .foregroundStyle(record.bestSeconds == nil ? palette.tertiaryInk : palette.accentDeep)
                .frame(width: 54, alignment: .trailing)

            Text("\(record.wins) / \(record.games)")
                .font(.gameMono(11, weight: .semibold))
                .foregroundStyle(palette.secondaryInk)
                .frame(width: 46, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(difficulty.title)，最佳时间 \(record.bestSeconds.map(TimeFormat.clock) ?? "暂无")，胜利 \(record.wins) 局，共 \(record.games) 局"
        )
    }

    private var dotColor: Color {
        switch difficulty {
        case .beginner: palette.mint
        case .intermediate: palette.sky
        case .expert: palette.flag
        }
    }
}

private struct SettingsRowButtonStyle: ButtonStyle {
    @Environment(\.gamePalette) private var palette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? palette.ink.opacity(0.035) : .clear)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
