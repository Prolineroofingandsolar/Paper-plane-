import SwiftUI
import SpriteKit

enum AppScreen {
    case menu
    case customize
    case playing
}

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @StateObject private var skinStore = SkinStore()
    @State private var appScreen: AppScreen = .menu

    var scene: GameScene {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.gameState = gameState
        scene.selectedSkin = skinStore.selectedSkin
        return scene
    }

    var body: some View {
        Group {
            switch appScreen {
            case .menu:
                MenuView(appScreen: $appScreen, bestScore: gameState.bestScore)

            case .customize:
                CustomizeView(appScreen: $appScreen, gameState: gameState, skinStore: skinStore)

            case .playing:
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
                                Button(action: {
                                    gameState.reset()
                                    appScreen = .menu
                                }) {
                                    Text("[ MENU ]")
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
                }
                .preferredColorScheme(.dark)
            }
        }
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
