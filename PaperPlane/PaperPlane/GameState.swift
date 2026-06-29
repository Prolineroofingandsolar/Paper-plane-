import Foundation
import Combine

class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var hasStarted: Bool = false
    @Published var bestScore: Int = 0

    private let bestScoreKey = "bestScore"

    init() {
        bestScore = UserDefaults.standard.integer(forKey: bestScoreKey)
    }

    func reset() {
        score = 0
        isGameOver = false
        hasStarted = false
    }

    func addPoint() {
        score += 1
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
        }
    }

    func triggerGameOver() {
        isGameOver = true
    }
}
