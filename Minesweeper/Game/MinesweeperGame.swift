import Foundation
import Observation

/// The complete, UI-independent rules of a single game of Minesweeper.
@MainActor
@Observable
final class MinesweeperGame {
    let id = UUID()
    let configuration: BoardConfiguration

    private(set) var cells: [Cell]
    private(set) var status: GameStatus = .ready
    private(set) var startedAt: Date?
    private(set) var endedAt: Date?
    private(set) var explodedIndex: Int?
    private(set) var flagCount = 0
    private(set) var revealedSafeCount = 0

    @ObservationIgnored private let minePlacer: MinePlacer

    init(
        configuration: BoardConfiguration,
        minePlacer: @escaping MinePlacer = MineGenerator.firstClickSafe
    ) {
        self.configuration = configuration
        self.minePlacer = minePlacer
        self.cells = Array(repeating: Cell(), count: configuration.cellCount)
    }

    // MARK: - Derived state

    var safeCellCount: Int { configuration.cellCount - configuration.mineCount }
    var remainingMines: Int { max(0, configuration.mineCount - flagCount) }
    var progress: Double {
        guard safeCellCount > 0 else { return 0 }
        return min(1, Double(revealedSafeCount) / Double(safeCellCount))
    }

    var finishedSeconds: Int? {
        guard let startedAt, let endedAt else { return nil }
        // Truncate, matching the live timer's whole-second ticks.
        return max(1, Int(endedAt.timeIntervalSince(startedAt)))
    }

    var mineIndices: [Int] {
        cells.indices.filter { cells[$0].hasMine }
    }

    func cell(row: Int, column: Int) -> Cell {
        cells[configuration.index(row: row, column: column)]
    }

    func elapsedSeconds(at date: Date = .now) -> Int {
        guard let startedAt else { return 0 }
        let end = endedAt ?? date
        return max(0, Int(end.timeIntervalSince(startedAt)))
    }

    // MARK: - Player actions

    /// Reveals a cell. Tapping an already revealed number chords its neighbours.
    /// Returns `true` when the board changed.
    @discardableResult
    func reveal(at index: Int) -> Bool {
        guard status.isActive, configuration.contains(index: index) else { return false }

        switch cells[index].state {
        case .flagged:
            return false

        case .revealed:
            return chord(at: index)

        case .hidden:
            if status == .ready {
                prepareBoard(openingIndex: index)
                status = .playing
                startedAt = .now
            }

            if cells[index].hasMine {
                lose(explodedAt: index)
                return true
            }

            revealFlood(from: index)
            finishIfWon()
            return true
        }
    }

    /// Places or removes a flag. Returns `true` when the board changed.
    @discardableResult
    func toggleFlag(at index: Int) -> Bool {
        guard status.isActive, configuration.contains(index: index) else { return false }

        switch cells[index].state {
        case .hidden:
            guard flagCount < configuration.mineCount else { return false }
            cells[index].state = .flagged
            flagCount += 1
            return true

        case .flagged:
            cells[index].state = .hidden
            flagCount -= 1
            return true

        case .revealed:
            return false
        }
    }

    // MARK: - Board setup

    private func prepareBoard(openingIndex: Int) {
        let mines = minePlacer(configuration, openingIndex)
        assert(mines.count == configuration.mineCount, "The mine placer returned an unexpected number of mines.")
        assert(!mines.contains(openingIndex), "The opening cell must always be safe.")

        for index in mines where configuration.contains(index: index) {
            cells[index].hasMine = true
        }

        for index in cells.indices {
            cells[index].adjacentMineCount = neighbours(of: index).reduce(into: 0) { count, neighbour in
                if cells[neighbour].hasMine { count += 1 }
            }
        }
    }

    private func revealFlood(from start: Int) {
        var stack = [start]

        while let index = stack.popLast() {
            guard cells[index].state == .hidden, !cells[index].hasMine else { continue }
            cells[index].state = .revealed
            revealedSafeCount += 1

            guard cells[index].adjacentMineCount == 0 else { continue }
            for neighbour in neighbours(of: index) where cells[neighbour].state == .hidden && !cells[neighbour].hasMine {
                stack.append(neighbour)
            }
        }
    }

    private func chord(at index: Int) -> Bool {
        guard status == .playing else { return false }
        let origin = cells[index]
        guard origin.isRevealed, origin.adjacentMineCount > 0 else { return false }

        let adjacent = neighbours(of: index)
        let flaggedCount = adjacent.reduce(into: 0) { count, neighbour in
            if cells[neighbour].state == .flagged { count += 1 }
        }
        guard flaggedCount == origin.adjacentMineCount else { return false }

        let hiddenNeighbours = adjacent.filter { cells[$0].state == .hidden }
        guard !hiddenNeighbours.isEmpty else { return false }

        for neighbour in hiddenNeighbours {
            if cells[neighbour].hasMine {
                lose(explodedAt: neighbour)
                return true
            }
        }

        for neighbour in hiddenNeighbours {
            revealFlood(from: neighbour)
        }
        finishIfWon()
        return true
    }

    // MARK: - End of game

    private func finishIfWon() {
        guard status == .playing, revealedSafeCount == safeCellCount else { return }

        status = .won
        endedAt = .now
        for index in cells.indices where cells[index].hasMine && cells[index].state == .hidden {
            cells[index].state = .flagged
            flagCount += 1
        }
    }

    private func lose(explodedAt index: Int) {
        guard status.isActive else { return }
        status = .lost
        endedAt = .now
        explodedIndex = index

        if cells[index].state == .hidden {
            cells[index].state = .revealed
        }
        cells[index].isExploded = true

        for mine in cells.indices where cells[mine].hasMine && cells[mine].state == .hidden {
            cells[mine].state = .revealed
        }

        for safe in cells.indices where !cells[safe].hasMine && cells[safe].state == .flagged {
            cells[safe].isWrongFlag = true
        }
    }

    // MARK: - Grid helpers

    private func neighbours(of index: Int) -> [Int] {
        let row = configuration.row(of: index)
        let column = configuration.column(of: index)
        var result: [Int] = []
        result.reserveCapacity(8)

        for rowOffset in -1...1 {
            for columnOffset in -1...1 {
                guard rowOffset != 0 || columnOffset != 0 else { continue }
                let neighbourRow = row + rowOffset
                let neighbourColumn = column + columnOffset
                guard (0..<configuration.rows).contains(neighbourRow),
                      (0..<configuration.columns).contains(neighbourColumn) else {
                    continue
                }
                result.append(configuration.index(row: neighbourRow, column: neighbourColumn))
            }
        }
        return result
    }
}
