import Foundation
import Testing
@testable import Minesweeper

@MainActor
@Suite("Minesweeper game rules")
struct MinesweeperGameTests {
    private func deterministicGame(
        columns: Int,
        rows: Int,
        mines: Set<Int>
    ) -> MinesweeperGame {
        let configuration = BoardConfiguration(columns: columns, rows: rows, mineCount: mines.count)
        return MinesweeperGame(configuration: configuration) { _, _ in mines }
    }

    @Test("A new board is ready and completely hidden")
    func newGameIsReady() {
        let game = MinesweeperGame(configuration: Difficulty.beginner.configuration)

        #expect(game.status == .ready)
        #expect(game.cells.count == 81)
        #expect(game.cells.map(\.state) == Array(repeating: CellState.hidden, count: 81))
        #expect(game.flagCount == 0)
        #expect(game.startedAt == nil)
        #expect(game.finishedSeconds == nil)
        #expect(game.remainingMines == 10)
        #expect(game.progress == 0)
    }

    @Test("The first tap is always safe and places exactly the configured mines")
    func firstTapIsSafe() {
        for _ in 0..<30 {
            let configuration = Difficulty.intermediate.configuration
            let game = MinesweeperGame(configuration: configuration)
            let opening = Int.random(in: 0..<configuration.cellCount)

            game.reveal(at: opening)

            #expect(game.status != .lost)
            #expect(game.cells[opening].isRevealed)
            #expect(!game.cells[opening].hasMine)
            #expect(game.mineIndices.count == configuration.mineCount)
            #expect(game.revealedSafeCount > 0)
            #expect(game.startedAt != nil)

            let safeZone = MineGenerator.safeIndices(around: opening, configuration: configuration)
            for mine in game.mineIndices {
                #expect(!safeZone.contains(mine))
            }
        }
    }

    @Test("Flags are capped at the mine count and can be removed")
    func flagsAreCappedAndToggle() {
        let game = deterministicGame(columns: 3, rows: 3, mines: [7, 8])

        #expect(game.toggleFlag(at: 0))
        #expect(game.toggleFlag(at: 1))
        #expect(game.cells[0].isFlagged)
        #expect(game.flagCount == 2)
        #expect(game.remainingMines == 0)
        #expect(game.startedAt == nil, "Flagging before the opening move should not start the clock.")

        #expect(!game.toggleFlag(at: 2))
        #expect(game.cells[2].isHidden)

        #expect(game.toggleFlag(at: 0))
        #expect(game.cells[0].isHidden)
        #expect(game.flagCount == 1)
        #expect(game.remainingMines == 1)
    }

    @Test("Empty regions flood open and a win flags the remaining mines")
    func floodRevealAndWin() {
        let game = deterministicGame(columns: 3, rows: 3, mines: [8])

        let changed = game.reveal(at: 0)

        #expect(changed)
        #expect(game.status == .won)
        #expect(game.revealedSafeCount == 8)
        #expect(game.cells[8].isFlagged)
        #expect(game.flagCount == 1)
        #expect(game.remainingMines == 0)
        #expect(game.finishedSeconds != nil)
        #expect(game.reveal(at: 0) == false)
        #expect(game.toggleFlag(at: 0) == false)
    }

    @Test("Revealing a mine ends the game and marks wrong flags")
    func mineExplosionLoses() {
        let game = deterministicGame(columns: 3, rows: 3, mines: [8])

        // Keep a safe cell flagged so the opening flood cannot already win.
        game.toggleFlag(at: 7)
        game.reveal(at: 0)

        #expect(game.status == .playing)
        #expect(game.revealedSafeCount == 7)

        game.reveal(at: 8)

        #expect(game.status == .lost)
        #expect(game.explodedIndex == 8)
        #expect(game.cells[8].isExploded)
        #expect(game.cells[8].isRevealed)
        #expect(game.cells[7].isWrongFlag)
        #expect(game.finishedSeconds != nil)
        #expect(!game.toggleFlag(at: 1))
    }

    @Test("Chording reveals hidden neighbours when flags match the number")
    func chordRevealsNeighbours() {
        let game = deterministicGame(columns: 3, rows: 3, mines: [8])

        // Block the flood with a safe flag, then open the board.
        game.toggleFlag(at: 7)
        game.reveal(at: 0)
        #expect(game.status == .playing)
        #expect(game.cells[5].isRevealed)
        #expect(game.cells[5].adjacentMineCount == 1)

        // Replace the blocking flag with a correct flag on the mine.
        game.toggleFlag(at: 7)
        game.toggleFlag(at: 8)

        let changed = game.reveal(at: 5)

        #expect(changed)
        #expect(game.cells[7].isRevealed)
        #expect(game.status == .won)
    }

    @Test("Chording does nothing when the flag count does not match")
    func chordRequiresMatchingFlags() {
        let game = deterministicGame(columns: 3, rows: 3, mines: [8])

        game.toggleFlag(at: 7)
        game.reveal(at: 0)
        game.toggleFlag(at: 7)

        #expect(game.reveal(at: 5) == false)
        #expect(game.status == .playing)
    }

    @Test("Every difficulty has a valid, classic board")
    func difficultyConfigurations() {
        #expect(Difficulty.beginner.configuration == BoardConfiguration(columns: 9, rows: 9, mineCount: 10))
        #expect(Difficulty.intermediate.configuration == BoardConfiguration(columns: 16, rows: 16, mineCount: 40))
        #expect(Difficulty.expert.configuration == BoardConfiguration(columns: 30, rows: 16, mineCount: 99))

        for difficulty in Difficulty.allCases {
            #expect(difficulty.configuration.mineCount < difficulty.configuration.cellCount)
            #expect(!difficulty.summary.isEmpty)
        }
    }

    @Test("Mine generation always returns the right count")
    func mineGenerationCount() {
        for difficulty in Difficulty.allCases {
            for _ in 0..<20 {
                let configuration = difficulty.configuration
                let opening = Int.random(in: 0..<configuration.cellCount)
                let mines = MineGenerator.random(configuration: configuration, safeIndex: opening)
                #expect(mines.count == configuration.mineCount)
                #expect(!mines.contains(opening))
            }
        }
    }
}
