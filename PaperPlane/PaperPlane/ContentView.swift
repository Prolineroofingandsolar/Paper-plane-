import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameState = GameState()

    var scene: GameScene {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.gameState = gameState
        return scene
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Text("Score: \(gameState.score)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                        .padding()
                }
                Spacer()
            }

            if gameState.isGameOver {
                GameOverView(score: gameState.score, bestScore: gameState.bestScore) {
                    gameState.reset()
                }
            }

            if !gameState.hasStarted && !gameState.isGameOver {
                StartView()
            }
        }
    }
}

struct StartView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("✈️")
                .font(.system(size: 80))
            Text("Paper Plane")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text("Tap to fly!")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .shadow(radius: 20)
    }
}

struct GameOverView: View {
    let score: Int
    let bestScore: Int
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            VStack(spacing: 8) {
                Text("Score: \(score)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                Text("Best: \(bestScore)")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            Button(action: onRestart) {
                Text("Play Again")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(30)
            }
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .shadow(radius: 20)
    }
}
