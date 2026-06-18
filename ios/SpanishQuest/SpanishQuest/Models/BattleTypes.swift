import Foundation

enum TurnActor: String {
    case player
    case enemy

    var label: String {
        switch self {
        case .player:
            "Your turn"
        case .enemy:
            "Enemy turn"
        }
    }
}

enum BattleStatus {
    case fighting
    case won
    case lost
}

enum BattleAnimationKind: Equatable {
    case resetBattle
    case playerAttack(isHalfPower: Bool)
    case playerMiss
    case playerDodge
    case playerBlock
    case playerHurt
    case monsterAttack
    case monsterHurt
    case monsterDefeated
}

struct BattleAnimationEvent: Identifiable, Equatable {
    let id = UUID()
    let kind: BattleAnimationKind
}
