import Foundation

/// A closure-based mine placement strategy so the board can be deterministic in tests.
typealias MinePlacer = @Sendable (BoardConfiguration, _ safeIndex: Int) -> Set<Int>

enum MineGenerator {
    static func random(configuration: BoardConfiguration, safeIndex: Int) -> Set<Int> {
        var candidates = Set(0..<configuration.cellCount)

        // The first tap and its eight neighbours are always safe, which guarantees
        // that the opening tap also has a chance to open a useful area.
        let safeZone = safeIndices(around: safeIndex, configuration: configuration)
        candidates.subtract(safeZone)

        if candidates.count < configuration.mineCount {
            candidates = Set(0..<configuration.cellCount)
            candidates.remove(safeIndex)
        }

        guard candidates.count > configuration.mineCount else {
            return candidates
        }
        return Set(candidates.shuffled().prefix(configuration.mineCount))
    }

    /// The default placement policy: a random board with a safe opening area.
    static let firstClickSafe: MinePlacer = { configuration, safeIndex in
        random(configuration: configuration, safeIndex: safeIndex)
    }

    static func safeIndices(around index: Int, configuration: BoardConfiguration) -> Set<Int> {
        guard configuration.contains(index: index) else { return [] }
        let row = configuration.row(of: index)
        let column = configuration.column(of: index)
        var indices: Set<Int> = [index]

        for rowOffset in -1...1 {
            for columnOffset in -1...1 {
                let neighbourRow = row + rowOffset
                let neighbourColumn = column + columnOffset
                guard (0..<configuration.rows).contains(neighbourRow),
                      (0..<configuration.columns).contains(neighbourColumn) else {
                    continue
                }
                indices.insert(configuration.index(row: neighbourRow, column: neighbourColumn))
            }
        }
        return indices
    }
}
