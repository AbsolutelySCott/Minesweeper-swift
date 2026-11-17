import Foundation

/// A small, persistent record of a player's results.
struct PlayerStats: Equatable, Codable, Sendable {
    struct Record: Equatable, Codable, Sendable {
        var games = 0
        var wins = 0
        var bestSeconds: Int?

        var winRate: Double {
            games == 0 ? 0 : Double(wins) / Double(games)
        }
    }

    private(set) var records: [String: Record] = [:]

    func record(for difficulty: Difficulty) -> Record {
        records[difficulty.rawValue] ?? Record()
    }

    var totalGames: Int {
        records.values.reduce(0) { $0 + $1.games }
    }

    var totalWins: Int {
        records.values.reduce(0) { $0 + $1.wins }
    }

    var winRate: Double {
        totalGames == 0 ? 0 : Double(totalWins) / Double(totalGames)
    }

    /// Adds the result of a finished game. Returns `true` when a new best time was set.
    @discardableResult
    mutating func record(_ result: GameResult) -> Bool {
        let key = result.difficulty.rawValue
        var record = records[key] ?? Record()
        record.games += 1

        guard result.won else {
            records[key] = record
            return false
        }

        record.wins += 1
        let seconds = max(1, result.seconds)
        let isNewBest = record.bestSeconds.map { seconds < $0 } ?? true
        if isNewBest {
            record.bestSeconds = seconds
        }
        records[key] = record
        return isNewBest
    }

    mutating func reset() {
        records = [:]
    }
}

/// The outcome of one completed game, used by the result card and by stats.
struct GameResult: Equatable, Sendable {
    let difficulty: Difficulty
    let won: Bool
    let seconds: Int
    let isNewBest: Bool
}
