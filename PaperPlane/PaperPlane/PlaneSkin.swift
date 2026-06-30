import SwiftUI

struct PlaneSkin: Identifiable {
    let id: String
    let name: String
    let bodyColor: UIColor
    let strokeColor: UIColor
    let wingColor: UIColor
    let unlockScore: Int

    static let all: [PlaneSkin] = [
        PlaneSkin(id: "white", name: "STANDARD",
                  bodyColor: .white,
                  strokeColor: UIColor(white: 0.55, alpha: 1),
                  wingColor: UIColor(white: 0.86, alpha: 1),
                  unlockScore: 0),
        PlaneSkin(id: "red", name: "CRIMSON",
                  bodyColor: UIColor(red: 0.86, green: 0.18, blue: 0.18, alpha: 1),
                  strokeColor: UIColor(red: 0.5, green: 0.08, blue: 0.08, alpha: 1),
                  wingColor: UIColor(red: 0.95, green: 0.45, blue: 0.45, alpha: 1),
                  unlockScore: 5),
        PlaneSkin(id: "blue", name: "AZURE",
                  bodyColor: UIColor(red: 0.20, green: 0.45, blue: 0.95, alpha: 1),
                  strokeColor: UIColor(red: 0.08, green: 0.22, blue: 0.55, alpha: 1),
                  wingColor: UIColor(red: 0.55, green: 0.72, blue: 0.98, alpha: 1),
                  unlockScore: 15),
        PlaneSkin(id: "yellow", name: "AMBER",
                  bodyColor: UIColor(red: 0.95, green: 0.78, blue: 0.15, alpha: 1),
                  strokeColor: UIColor(red: 0.55, green: 0.42, blue: 0.05, alpha: 1),
                  wingColor: UIColor(red: 0.98, green: 0.88, blue: 0.5, alpha: 1),
                  unlockScore: 30),
        PlaneSkin(id: "green", name: "EMERALD",
                  bodyColor: UIColor(red: 0.18, green: 0.75, blue: 0.35, alpha: 1),
                  strokeColor: UIColor(red: 0.06, green: 0.4, blue: 0.16, alpha: 1),
                  wingColor: UIColor(red: 0.55, green: 0.92, blue: 0.65, alpha: 1),
                  unlockScore: 50),
    ]

    static func isUnlocked(_ skin: PlaneSkin, bestScore: Int) -> Bool {
        bestScore >= skin.unlockScore
    }
}

class SkinStore: ObservableObject {
    @Published var selectedSkinID: String
    private let key = "selectedSkinID"

    init() {
        selectedSkinID = UserDefaults.standard.string(forKey: key) ?? PlaneSkin.all[0].id
    }

    var selectedSkin: PlaneSkin {
        PlaneSkin.all.first(where: { $0.id == selectedSkinID }) ?? PlaneSkin.all[0]
    }

    func select(_ skin: PlaneSkin) {
        selectedSkinID = skin.id
        UserDefaults.standard.set(skin.id, forKey: key)
    }
}
