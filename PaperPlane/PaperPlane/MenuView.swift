import SwiftUI

struct MenuView: View {
    @Binding var appScreen: AppScreen
    let bestScore: Int

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            RetroOverlay {
                VStack(spacing: 16) {
                    Text("✈")
                        .font(.system(size: 60))
                    Text("PAPER PLANE")
                        .font(.system(size: 26, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                    Text("CHASE")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)

                    Text("HI SCORE \(String(format: "%03d", bestScore))")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(white: 0.7))

                    Spacer().frame(height: 10)

                    Button(action: { appScreen = .playing }) {
                        Text("[ PLAY ]")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(4)
                    }

                    Button(action: { appScreen = .customize }) {
                        Text("[ PLANES ]")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                            )
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
