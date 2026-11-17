import Foundation
import Observation

/// Owns the current game, the player's records, and the small amount of
/// presentation-independent game flow that sits between the two.
@MainActor
@Observable
final class GameModel {
    private enum Keys {
        static let difficulty = "minesweeper.difficulty"
        static let flagMode = "minesweeper.flagMode"
        static let stats = "minesweeper.stats.v1"
    }

    @ObservationIgnored private let defaults: UserDefaults

    private(set) var game: MinesweeperGame
    private(set) var difficulty: Difficulty
    private(set) var stats: PlayerStats
    private(set) var result: GameResult?
    private(set) var isFlagMode: Bool
    private(set) var recordedGameID: UUID?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedDifficulty = defaults.string(forKey: Keys.difficulty)
            .flatMap(Difficulty.init(rawValue:)) ?? .beginner
        difficulty = savedDifficulty
        game = MinesweeperGame(configuration: savedDifficulty.configuration)
        stats = Self.loadStats(from: defaults)
        isFlagMode = defaults.object(forKey: Keys.flagMode) as? Bool ?? false
        Haptics.prepare()
    }

    // MARK: - Game lifecycle

    func startNewGame() {
        game = MinesweeperGame(configuration: difficulty.configuration)
        result = nil
        recordedGameID = nil
        Haptics.impact(.light, intensity: 0.7)
    }

    func selectDifficulty(_ newDifficulty: Difficulty) {
        guard newDifficulty != difficulty else { return }
        difficulty = newDifficulty
        defaults.set(newDifficulty.rawValue, forKey: Keys.difficulty)
        startNewGame()
    }

    // MARK: - Player input

    func primaryTap(at index: Int) {
        guard !game.status.isOver else { return }
        if isFlagMode {
            flag(at: index)
        } else {
            reveal(at: index)
        }
    }

    func secondaryTap(at index: Int) {
        guard !game.status.isOver else { return }
        if isFlagMode {
            reveal(at: index)
        } else {
            flag(at: index)
        }
    }

    func toggleFlagMode() {
        isFlagMode.toggle()
        defaults.set(isFlagMode, forKey: Keys.flagMode)
        Haptics.selection()
    }

    private func reveal(at index: Int) {
        let revealedBefore = game.revealedSafeCount
        guard game.reveal(at: index) else { return }
        let newlyRevealed = max(0, game.revealedSafeCount - revealedBefore)
        provideFeedbackForMove(newlyRevealed: newlyRevealed)
        recordResultIfNeeded()
    }

    private func flag(at index: Int) {
        if game.toggleFlag(at: index) {
            Haptics.impact(.rigid, intensity: 0.8)
        } else {
            Haptics.impact(.soft, intensity: 0.35)
        }
    }

    private func provideFeedbackForMove(newlyRevealed: Int) {
        switch game.status {
        case .lost:
            Haptics.notify(.error)
        case .won:
            Haptics.notify(.success)
        default:
            // A single flip gets a crisp tap; opening a whole area gets a
            // slightly fuller bump.
            if newlyRevealed >= 3 {
                Haptics.impact(.medium, intensity: 0.85)
            } else {
                Haptics.impact(.light, intensity: 1)
            }
        }
    }

    private func recordResultIfNeeded() {
        guard game.status.isOver, recordedGameID != game.id else { return }
        recordedGameID = game.id

        let seconds = game.finishedSeconds ?? max(1, game.elapsedSeconds())
        let pending = GameResult(
            difficulty: difficulty,
            won: game.status == .won,
            seconds: seconds,
            isNewBest: false
        )
        let isNewBest = stats.record(pending)
        saveStats()
        result = GameResult(
            difficulty: difficulty,
            won: pending.won,
            seconds: seconds,
            isNewBest: isNewBest
        )
    }

    // MARK: - Records

    func bestSeconds(for difficulty: Difficulty) -> Int? {
        stats.record(for: difficulty).bestSeconds
    }

    var currentBestSeconds: Int? {
        bestSeconds(for: difficulty)
    }

    func resetStats() {
        stats.reset()
        saveStats()
        result = nil
    }

    private func saveStats() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: Keys.stats)
    }

    private static func loadStats(from defaults: UserDefaults) -> PlayerStats {
        guard let data = defaults.data(forKey: Keys.stats),
              let decoded = try? JSONDecoder().decode(PlayerStats.self, from: data) else {
            return PlayerStats()
        }
        return decoded
    }
}
