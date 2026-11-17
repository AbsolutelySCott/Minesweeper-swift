import SwiftUI

/// Shared chrome for the app's custom sheets.
struct SheetScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    @Environment(\.dismiss) private var dismiss
    @Environment(\.gamePalette) private var palette

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            GameBackground()

            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.gameRounded(28, weight: .bold))
                            .foregroundStyle(palette.ink)
                            .accessibilityAddTraits(.isHeader)

                        if let subtitle {
                            Text(subtitle)
                                .font(.gameRounded(12, weight: .medium))
                                .foregroundStyle(palette.secondaryInk)
                        }
                    }

                    Spacer(minLength: 8)

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(palette.secondaryInk)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay {
                                Circle().strokeBorder(palette.glassStroke, lineWidth: 0.8)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("关闭")
                    .accessibilityIdentifier("sheet-close")
                }
                .frame(maxWidth: 656)
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 14)

                ScrollView {
                    content
                        .frame(maxWidth: 620)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 36)
                        .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
        .presentationBackground(.clear)
    }
}
