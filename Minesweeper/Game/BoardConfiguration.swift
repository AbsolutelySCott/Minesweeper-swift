import Foundation

/// A immutable description of a minefield.
struct BoardConfiguration: Hashable, Sendable {
    let columns: Int
    let rows: Int
    let mineCount: Int

    init(columns: Int, rows: Int, mineCount: Int) {
        precondition(columns > 0 && rows > 0, "A board needs at least one cell.")
        precondition(mineCount >= 0 && mineCount < columns * rows, "A board needs at least one safe cell.")
        self.columns = columns
        self.rows = rows
        self.mineCount = mineCount
    }

    var cellCount: Int { columns * rows }

    var sizeLabel: String { "\(columns) × \(rows)" }

    func index(row: Int, column: Int) -> Int { row * columns + column }

    func row(of index: Int) -> Int { index / columns }

    func column(of index: Int) -> Int { index % columns }

    func contains(index: Int) -> Bool { (0..<cellCount).contains(index) }
}

/// The three classic difficulty levels.
enum Difficulty: String, CaseIterable, Codable, Identifiable, Sendable {
    case beginner
    case intermediate
    case expert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: "初级"
        case .intermediate: "中级"
        case .expert: "高级"
        }
    }

    var configuration: BoardConfiguration {
        switch self {
        case .beginner: BoardConfiguration(columns: 9, rows: 9, mineCount: 10)
        case .intermediate: BoardConfiguration(columns: 16, rows: 16, mineCount: 40)
        case .expert: BoardConfiguration(columns: 30, rows: 16, mineCount: 99)
        }
    }

    var summary: String {
        "\(configuration.sizeLabel) · \(configuration.mineCount) 雷"
    }
}
