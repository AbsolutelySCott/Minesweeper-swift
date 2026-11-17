import Foundation
import Testing
@testable import Minesweeper

@Suite("Player records")
struct PlayerStatsTests {
    private func result(_ difficulty: Difficulty, won: Bool, seconds: Int) -> GameResult {
        GameResult(difficulty: difficulty, won: won, seconds: seconds, isNewBest: false)
    }

    @Test("Wins and best times are recorded independently per difficulty")
    func recordsResults() {
        var stats = PlayerStats()

        let firstBest = stats.record(result(.beginner, won: true, seconds: 42))
        #expect(firstBest)
        #expect(stats.record(for: .beginner).bestSeconds == 42)
        #expect(stats.record(for: .beginner).games == 1)
        #expect(stats.record(for: .beginner).wins == 1)

        let slowerWin = stats.record(result(.beginner, won: true, seconds: 55))
        #expect(!slowerWin)
        #expect(stats.record(for: .beginner).bestSeconds == 42)

        let fasterWin = stats.record(result(.beginner, won: true, seconds: 31))
        #expect(fasterWin)
        #expect(stats.record(for: .beginner).bestSeconds == 31)

        let loss = stats.record(result(.beginner, won: false, seconds: 8))
        #expect(!loss)
        #expect(stats.record(for: .beginner).games == 4)
        #expect(stats.record(for: .beginner).wins == 3)

        let expertBest = stats.record(result(.expert, won: true, seconds: 120))
        #expect(expertBest)
        #expect(stats.record(for: .expert).bestSeconds == 120)
        #expect(stats.record(for: .beginner).bestSeconds == 31)
        #expect(stats.totalGames == 5)
        #expect(stats.totalWins == 4)
        #expect(abs(stats.winRate - 0.8) < 0.0001)
    }

    @Test("Losing times never become a best record")
    func lossesDoNotSetBest() {
        var stats = PlayerStats()
        _ = stats.record(result(.intermediate, won: false, seconds: 3))

        let record = stats.record(for: .intermediate)
        #expect(record.games == 1)
        #expect(record.wins == 0)
        #expect(record.bestSeconds == nil)
    }

    @Test("Records can be encoded, decoded, and reset")
    func codingAndReset() throws {
        var stats = PlayerStats()
        _ = stats.record(result(.beginner, won: true, seconds: 21))
        _ = stats.record(result(.expert, won: false, seconds: 9))

        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(PlayerStats.self, from: data)
        #expect(decoded == stats)
        #expect(decoded.record(for: .beginner).bestSeconds == 21)

        stats.reset()
        #expect(stats.totalGames == 0)
        #expect(stats.record(for: .beginner).bestSeconds == nil)
    }

    @Test("Time formatting keeps the game's retro feel")
    func timeFormatting() {
        #expect(TimeFormat.clock(0) == "00:00")
        #expect(TimeFormat.clock(9) == "00:09")
        #expect(TimeFormat.clock(75) == "01:15")
        #expect(TimeFormat.clock(3600) == "1:00:00")
        #expect(TimeFormat.counter(10) == "010")
        #expect(TimeFormat.counter(-1) == "000")
    }
}

@MainActor
@Suite("Game model persistence")
struct GameModelTests {
    private func makeDefaults() -> (UserDefaults, String) {
        let suite = "MinesweeperTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (defaults, suite)
    }

    @Test("Difficulty and flag mode survive a fresh model")
    func preferencesPersist() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        let model = GameModel(defaults: defaults)
        #expect(model.difficulty == .beginner)
        #expect(!model.isFlagMode)

        model.selectDifficulty(.expert)
        model.toggleFlagMode()

        let restored = GameModel(defaults: defaults)
        #expect(restored.difficulty == .expert)
        #expect(restored.game.configuration == Difficulty.expert.configuration)
        #expect(restored.isFlagMode)
    }

    @Test("Restarting resets the game and keeps the selected difficulty")
    func restartResetsTheBoard() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        let model = GameModel(defaults: defaults)
        model.selectDifficulty(.intermediate)
        model.primaryTap(at: 0)
        #expect(model.game.status != .ready)

        model.startNewGame()
        #expect(model.game.status == .ready)
        #expect(model.game.configuration == Difficulty.intermediate.configuration)
        #expect(model.result == nil)
    }
}
