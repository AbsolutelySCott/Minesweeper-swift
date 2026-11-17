import SwiftUI

/// Draws the entire board in one pass. Keeping the visual board in a Canvas is
/// substantially cheaper than building and compositing hundreds of gradient,
/// text, and symbol views on every reveal.
struct BoardCanvas: View {
    @Environment(\.gamePalette) private var palette
    let cells: [Cell]
    let configuration: BoardConfiguration
    let tile: CGFloat
    let spacing: CGFloat

    private var cornerRadius: CGFloat {
        min(9, max(2.5, tile * 0.17))
    }

    private var numberFontSize: CGFloat {
        min(30, max(10, tile * 0.54))
    }

    private var contentSize: CGSize {
        CGSize(
            width: CGFloat(configuration.columns) * tile + CGFloat(configuration.columns - 1) * spacing,
            height: CGFloat(configuration.rows) * tile + CGFloat(configuration.rows - 1) * spacing
        )
    }

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, _ in
            for row in 0..<configuration.rows {
                for column in 0..<configuration.columns {
                    let index = configuration.index(row: row, column: column)
                    let cell = cells[index]

                    // Plain hidden tiles are painted once by the equatable
                    // backplate below. This canvas only repaints cells whose
                    // state differs from that backplate.
                    guard cell.isRevealed || cell.isFlagged || cell.isExploded else {
                        continue
                    }

                    let rect = CGRect(
                        x: CGFloat(column) * (tile + spacing),
                        y: CGFloat(row) * (tile + spacing),
                        width: tile,
                        height: tile
                    )
                    draw(cell: cell, in: rect, context: &context)
                }
            }
        }
        .frame(width: contentSize.width, height: contentSize.height)
        .accessibilityHidden(true)
    }

    private func draw(cell: Cell, in rect: CGRect, context: inout GraphicsContext) {
        let shape = Path(roundedRect: rect, cornerRadius: cornerRadius)

        if cell.isExploded {
            drawExploded(cell: cell, rect: rect, shape: shape, context: &context)
            return
        }

        if cell.isRevealed {
            drawRevealed(cell: cell, rect: rect, shape: shape, context: &context)
            return
        }

        if cell.isFlagged {
            // The flag cell is opaque so it completely covers the hidden
            // backplate underneath.
            drawHidden(shape: shape, rect: rect, context: &context)
            drawFlag(in: rect, context: &context)
            if cell.isWrongFlag {
                drawWrongBadge(in: rect, context: &context)
            }
        }
    }

    private func drawHidden(shape: Path, rect: CGRect, context: inout GraphicsContext) {
        // A flat fill is deliberately used here instead of a per-tile gradient.
        // It removes hundreds of gradient shadings from every reveal while the
        // stroke and glass highlight keep the tiles readable.
        context.fill(shape, with: .color(palette.hiddenFill))
        context.stroke(shape, with: .color(Color.white.opacity(0.10)), lineWidth: 0.6)

        if tile >= 26 {
            let highlightRect = CGRect(
                x: rect.minX + tile * 0.12,
                y: rect.minY + tile * 0.12,
                width: tile * 0.52,
                height: max(1, tile * 0.09)
            )
            let highlight = Path(
                roundedRect: highlightRect,
                cornerRadius: highlightRect.height / 2
            )
            context.fill(highlight, with: .color(Color.white.opacity(0.05)))
        }
    }

    private func drawRevealed(cell: Cell, rect: CGRect, shape: Path, context: inout GraphicsContext) {
        context.fill(shape, with: .color(palette.revealedFill))
        context.stroke(shape, with: .color(palette.revealedStroke), lineWidth: 0.5)

        if cell.hasMine {
            drawBomb(in: rect, exploded: false, context: &context)
        } else if cell.adjacentMineCount > 0 {
            let text = Text("\(cell.adjacentMineCount)")
                .font(.system(size: numberFontSize, weight: .black, design: .rounded))
                .foregroundStyle(palette.number(cell.adjacentMineCount))
            context.draw(text, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
        }
    }

    private func drawExploded(cell: Cell, rect: CGRect, shape: Path, context: inout GraphicsContext) {
        context.fill(
            shape,
            with: .linearGradient(
                Gradient(colors: [Color(hex: 0xFF8268), palette.dangerDeep]),
                startPoint: CGPoint(x: rect.minX, y: rect.minY),
                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
            )
        )
        context.stroke(shape, with: .color(Color.white.opacity(0.30)), lineWidth: 0.8)
        drawBomb(in: rect, exploded: true, context: &context)
    }

    private func drawBomb(in rect: CGRect, exploded: Bool, context: inout GraphicsContext) {
        let text = Text(exploded ? "💥" : "💣")
            .font(.system(size: max(10, tile * (exploded ? 0.60 : 0.58))))
        context.draw(text, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
    }

    private func drawFlag(in rect: CGRect, context: inout GraphicsContext) {
        let flagWidth = max(6, tile * 0.36)
        let flagHeight = max(4, tile * 0.26)
        let poleWidth = max(1, tile * 0.055)
        let poleHeight = max(8, tile * 0.48)
        let poleX = rect.midX - flagWidth * 0.38
        let poleTop = rect.midY - poleHeight * 0.48
        let poleBottom = poleTop + poleHeight

        let poleRect = CGRect(
            x: poleX - poleWidth / 2,
            y: poleTop,
            width: poleWidth,
            height: poleBottom - poleTop
        )
        let pole = Path(roundedRect: poleRect, cornerRadius: poleWidth / 2)
        let poleColor = palette.flagHighlight
        context.fill(pole, with: .color(poleColor.opacity(0.9)))

        var pennant = Path()
        pennant.move(to: CGPoint(x: poleX + poleWidth / 2, y: poleTop + poleHeight * 0.06))
        pennant.addLine(to: CGPoint(x: poleX + flagWidth, y: poleTop + flagHeight * 0.34))
        pennant.addLine(to: CGPoint(x: poleX + poleWidth / 2, y: poleTop + flagHeight * 0.72))
        pennant.closeSubpath()

        context.fill(
            pennant,
            with: .linearGradient(
                Gradient(colors: [palette.flagHighlight, palette.flag, palette.flagDeep]),
                startPoint: CGPoint(x: poleX, y: poleTop),
                endPoint: CGPoint(x: poleX + flagWidth, y: poleTop + flagHeight)
            )
        )
        context.stroke(pennant, with: .color(Color.black.opacity(0.18)), lineWidth: 0.4)
    }

    private func drawWrongBadge(in rect: CGRect, context: inout GraphicsContext) {
        let badgeDiameter = max(9, tile * 0.34)
        let badgeRect = CGRect(
            x: rect.maxX - badgeDiameter - tile * 0.06,
            y: rect.maxY - badgeDiameter - tile * 0.06,
            width: badgeDiameter,
            height: badgeDiameter
        )
        context.fill(Path(ellipseIn: badgeRect), with: .color(palette.danger))
        context.stroke(Path(ellipseIn: badgeRect), with: .color(Color.white.opacity(0.5)), lineWidth: 0.5)

        var cross = Path()
        let inset = badgeDiameter * 0.3
        cross.move(to: CGPoint(x: badgeRect.minX + inset, y: badgeRect.minY + inset))
        cross.addLine(to: CGPoint(x: badgeRect.maxX - inset, y: badgeRect.maxY - inset))
        cross.move(to: CGPoint(x: badgeRect.maxX - inset, y: badgeRect.minY + inset))
        cross.addLine(to: CGPoint(x: badgeRect.minX + inset, y: badgeRect.maxY - inset))
        context.stroke(cross, with: .color(.white), style: StrokeStyle(lineWidth: max(1, badgeDiameter * 0.14), lineCap: .round))
    }
}


/// Paints every cell as an untouched hidden tile. Because this view has no
/// dependency on the cell states, SwiftUI can keep its canvas cached across
/// reveals; the smaller overlay above only redraws cells that changed.
struct BoardHiddenCanvas: View, Equatable {
    @Environment(\.gamePalette) private var palette
    let columns: Int
    let rows: Int
    let tile: CGFloat
    let spacing: CGFloat
    let themeToken: String

    private var cornerRadius: CGFloat {
        min(9, max(2.5, tile * 0.17))
    }

    private var contentSize: CGSize {
        CGSize(
            width: CGFloat(columns) * tile + CGFloat(columns - 1) * spacing,
            height: CGFloat(rows) * tile + CGFloat(rows - 1) * spacing
        )
    }

    nonisolated static func == (lhs: BoardHiddenCanvas, rhs: BoardHiddenCanvas) -> Bool {
        lhs.columns == rhs.columns
            && lhs.rows == rhs.rows
            && lhs.tile == rhs.tile
            && lhs.spacing == rhs.spacing
            && lhs.themeToken == rhs.themeToken
    }

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, _ in
            for row in 0..<rows {
                for column in 0..<columns {
                    let rect = CGRect(
                        x: CGFloat(column) * (tile + spacing),
                        y: CGFloat(row) * (tile + spacing),
                        width: tile,
                        height: tile
                    )
                    let shape = Path(roundedRect: rect, cornerRadius: cornerRadius)
                    context.fill(shape, with: .color(palette.hiddenFill))
                    context.stroke(shape, with: .color(Color.white.opacity(0.10)), lineWidth: 0.6)

                    if tile >= 26 {
                        let highlightRect = CGRect(
                            x: rect.minX + tile * 0.12,
                            y: rect.minY + tile * 0.12,
                            width: tile * 0.52,
                            height: max(1, tile * 0.09)
                        )
                        let highlight = Path(
                            roundedRect: highlightRect,
                            cornerRadius: highlightRect.height / 2
                        )
                        context.fill(highlight, with: .color(Color.white.opacity(0.05)))
                    }
                }
            }
        }
        .frame(width: contentSize.width, height: contentSize.height)
        .accessibilityHidden(true)
    }
}
