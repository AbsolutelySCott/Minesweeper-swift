import Foundation

enum CellState: String, Equatable, Sendable {
    case hidden
    case revealed
    case flagged
}

struct Cell: Equatable, Sendable {
    var hasMine = false
    var adjacentMineCount = 0
    var state: CellState = .hidden
    var isExploded = false
    var isWrongFlag = false

    var isHidden: Bool { state == .hidden }
    var isRevealed: Bool { state == .revealed }
    var isFlagged: Bool { state == .flagged }
}

enum GameStatus: String, Equatable, Sendable {
    case ready
    case playing
    case won
    case lost

    var isOver: Bool { self == .won || self == .lost }
    var isActive: Bool { self == .ready || self == .playing }
}
