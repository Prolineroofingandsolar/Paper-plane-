import SwiftUI

struct PlanePreviewShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.05))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.65))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.85))
        path.closeSubpath()
        return path
    }
}

struct CustomizeView: View {
    @Binding var appScreen: AppScreen
    @ObservedObject var gameState: GameState
    @ObservedObject var skinStore: SkinStore

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("PLANES")
                    .font(.system(size: 26, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.top, 40)

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(PlaneSkin.all) { skin in
                        skinCard(skin)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: { appScreen = .menu }) {
                    Text("[ BACK ]")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                        )
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func skinCard(_ skin: PlaneSkin) -> some View {
        let unlocked = PlaneSkin.isUnlocked(skin, bestScore: gameState.bestScore)
        let selected = skinStore.selectedSkinID == skin.id

        return VStack(spacing: 8) {
            PlanePreviewShape()
                .fill(unlocked ? Color(skin.bodyColor) : Color(white: 0.3))
                .frame(width: 60, height: 60)
                .opacity(unlocked ? 1 : 0.5)

            Text(skin.name)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(unlocked ? .white : Color(white: 0.5))

            if !unlocked {
                Text("UNLOCK AT \(String(format: "%03d", skin.unlockScore))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            } else if selected {
                Text("SELECTED")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            } else {
                Text(" ")
                    .font(.system(size: 10, design: .monospaced))
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.14))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(selected ? Color.yellow : Color.white.opacity(0.25), lineWidth: selected ? 2 : 1)
        )
        .cornerRadius(6)
        .onTapGesture {
            if unlocked {
                skinStore.select(skin)
            }
        }
    }
}
