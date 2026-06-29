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
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%03d", gameState.score))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("HI \(String(format: "%03d", gameState.bestScore))")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(white: 0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                Spacer()
            }

            if gameState.isGameOver {
                RetroOverlay {
                    VStack(spacing: 12) {
                        Text("GAME OVER")
                            .font(.system(size: 30, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                        Text(String(format: "SCORE  %03d", gameState.score))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                        Text(String(format: "BEST   %03d", gameState.bestScore))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(white: 0.8))
                        Spacer().frame(height: 8)
                        Button(action: { gameState.reset() }) {
                            Text("[ PLAY AGAIN ]")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(4)
                        }
                    }
                }
            }

            if !gameState.hasStarted && !gameState.isGameOver {
                RetroOverlay {
                    VStack(spacing: 14) {
                        Text("✈")
                            .font(.system(size: 60))
                        Text("PAPER PLANE")
                            .font(.system(size: 26, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                        Text("CHASE")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                        Spacer().frame(height: 6)
                        Text("TAP & DRAG TO STEER")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(white: 0.7))
                        Text("TAP TO START")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .opacity(0.9)
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct RetroOverlay<Content: View>: View {
    let content: () -> Content
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack {
                content()
            }
            .padding(32)
            .background(Color(white: 0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
            )
            .cornerRadius(6)
        }
    }
}
