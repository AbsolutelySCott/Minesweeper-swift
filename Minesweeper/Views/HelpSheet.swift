import SwiftUI

struct HelpSheet: View {
    @State private var detent: PresentationDetent = .large

    var body: some View {
        SheetScaffold(title: "玩法", subtitle: "三分钟成为排雷专家") {
            VStack(spacing: 18) {
                introCard
                stepsCard
                firstTapNote
                chordNote
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
    }

    private var introCard: some View {
        HStack(spacing: 18) {
            MiniBoardDemo()

            VStack(alignment: .leading, spacing: 7) {
                Text("找出全部地雷")
                    .font(.gameRounded(19, weight: .bold))
                    .foregroundStyle(Theme.ink)

                Text("数字代表它周围八格中地雷的数量。标出全部地雷，并翻开其余所有安全方格，就能赢下这一局。")
                    .font(.gameRounded(12.5, weight: .regular))
                    .foregroundStyle(Theme.secondaryInk)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 26)
    }

    private var stepsCard: some View {
        VStack(spacing: 0) {
            helpStep(
                number: 1,
                icon: "hand.tap.fill",
                title: "翻开方格",
                detail: "轻点任意未翻开的方格。第一次点击以及它周围八格一定安全。"
            )

            stepDivider

            helpStep(
                number: 2,
                icon: "flag.fill",
                title: "插旗标记",
                detail: "在翻开模式下长按未翻开方格插旗；开启「标记模式」后，轻点插旗、长按翻开。"
            )

            stepDivider

            helpStep(
                number: 3,
                icon: "number",
                title: "读懂数字",
                detail: "数字是周围八格中的地雷数。把全部地雷标出后，翻开所有安全的方格。"
            )

            stepDivider

            helpStep(
                number: 4,
                icon: "bolt.fill",
                title: "快速翻开",
                detail: "当数字周围的旗子数量与数字一致时，轻点该数字，可一次翻开周围的方格。"
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .glassPanel(cornerRadius: 26)
    }

    private var firstTapNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.mint)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text("安全的第一次点击")
                    .font(.gameRounded(12, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("每局开始时，第一次点击的位置及其周围八格永远不会布雷，让你总能安全开局。")
                    .font(.gameRounded(11.5, weight: .regular))
                    .foregroundStyle(Theme.secondaryInk)
                    .lineSpacing(2)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.mint.opacity(0.09))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.mint.opacity(0.16), lineWidth: 0.8)
        }
    }

    private var chordNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.tertiaryInk)
            Text("提示：标记模式更适合大棋盘，单手也能轻松插旗。")
                .font(.gameRounded(10.5, weight: .medium))
                .foregroundStyle(Theme.tertiaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    private func helpStep(number: Int, icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                Circle()
                    .fill(Theme.gold.opacity(0.13))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.goldDeep)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(String(format: "%02d", number))
                        .font(.gameMono(8.5, weight: .bold))
                        .foregroundStyle(Theme.tertiaryInk)
                    Text(title)
                        .font(.gameRounded(13.5, weight: .bold))
                        .foregroundStyle(Theme.ink)
                }

                Text(detail)
                    .font(.gameRounded(11.5, weight: .regular))
                    .foregroundStyle(Theme.secondaryInk)
                    .lineSpacing(2.5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }

    private var stepDivider: some View {
        Rectangle()
            .fill(Theme.ink.opacity(0.07))
            .frame(height: 0.7)
            .padding(.leading, 47)
            .accessibilityHidden(true)
    }
}

private struct MiniBoardDemo: View {
    private let tiles: [[String?]] = [
        ["1", "1", "1"],
        ["1", nil, "1"],
        ["1", "1", "1"]
    ]

    var body: some View {
        VStack(spacing: 3) {
            ForEach(tiles.indices, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(tiles[row].indices, id: \.self) { column in
                        tile(value: tiles[row][column])
                    }
                }
            }
        }
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.boardTop, Theme.boardBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.8)
        }
        .rotationEffect(.degrees(-3))
        .shadow(color: Color.black.opacity(0.22), radius: 12, x: 0, y: 8)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func tile(value: String?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    value == nil
                        ? AnyShapeStyle(LinearGradient(colors: [Theme.hiddenTop, Theme.hiddenBottom], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(LinearGradient(colors: [Theme.revealedTop, Theme.revealedBottom], startPoint: .top, endPoint: .bottom))
                )

            if let value {
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.number(1))
            } else {
                Image(systemName: "flag.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Theme.goldGradient)
            }
        }
        .frame(width: 28, height: 28)
    }
}
