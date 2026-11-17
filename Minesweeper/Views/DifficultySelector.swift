import SwiftUI

struct DifficultySelector: View {
    @Environment(\.gamePalette) private var palette
    let selection: Difficulty
    let onSelect: (Difficulty) -> Void

    @Namespace private var selectionNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Difficulty.allCases) { difficulty in
                let isSelected = difficulty == selection

                Button {
                    onSelect(difficulty)
                } label: {
                    Text(difficulty.title)
                        .font(.gameRounded(14, weight: .bold))
                        .foregroundStyle(isSelected ? palette.onAccent : palette.secondaryInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .contentShape(.capsule)
                        .background {
                            if isSelected {
                                Capsule(style: .continuous)
                                    .fill(palette.accentGradient)
                                    .matchedGeometryEffect(id: "selectedDifficulty", in: selectionNamespace)
                                    .shadow(color: palette.accentDeep.opacity(0.28), radius: 6, x: 0, y: 3)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(difficulty.title)，\(difficulty.summary)")
                .accessibilityHint(isSelected ? "当前难度" : "开始一局\(difficulty.title)游戏")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("difficulty-\(difficulty.rawValue)")
            }
        }
        .padding(4)
        .glassEffect(.regular, in: Capsule(style: .continuous))
        .animation(reduceMotion ? nil : .spring(duration: 0.32, bounce: 0.2), value: selection)
        .accessibilityElement(children: .contain)
    }
}
