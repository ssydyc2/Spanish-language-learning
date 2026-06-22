import Foundation
import SwiftUI

@MainActor
final class BattleViewModel: ObservableObject {
    @Published private(set) var playerHP = 100
    @Published private(set) var monsterHP = 100
    @Published private(set) var actor: TurnActor = .player
    @Published private(set) var attempt = 1
    @Published private(set) var status: BattleStatus = .fighting
    @Published private(set) var prompt: QuizPrompt
    @Published var feedback = "The forest imp blocks the rescue trail. Answer correctly to strike first."
    @Published var animationEvent: BattleAnimationEvent?

    private let quizEngine: QuizEngine
    private let audioPlayer = AudioPlayer()
    private let playerDamage = 24
    private let enemyDamage = 18

    init(vocabulary: Vocabulary = VocabularyLoader.load()) {
        quizEngine = QuizEngine(vocabulary: vocabulary)
        prompt = quizEngine.nextPrompt()
    }

    var expectedAnswerSummary: String {
        prompt.acceptedAnswers.joined(separator: " / ")
    }

    func answer(_ value: String) {
        guard status == .fighting else {
            restart()
            return
        }

        if prompt.accepts(value) {
            resolveSuccess(isSecondChance: attempt == 2)
        } else if attempt == 1 {
            attempt = 2
            feedback = "Not quite. Focus: one more chance for a half result."
        } else {
            resolveFailure()
        }
    }

    func playPromptAudio() {
        audioPlayer.play(path: prompt.audioPath)
    }

    func restart() {
        playerHP = 100
        monsterHP = 100
        actor = .player
        attempt = 1
        status = .fighting
        feedback = "The forest imp blocks the rescue trail. Answer correctly to strike first."
        prompt = quizEngine.nextPrompt()
        emit(.resetBattle)

        if prompt.audioPath != nil {
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                playPromptAudio()
            }
        }
    }

    private func resolveSuccess(isSecondChance: Bool) {
        switch actor {
        case .player:
            let damage = isSecondChance ? playerDamage / 2 : playerDamage
            monsterHP = max(0, monsterHP - damage)
            feedback = isSecondChance ? "Recovered! Half-power hit." : "Clean hit! Full damage."
            emit(.playerAttack(isHalfPower: isSecondChance))

            if monsterHP == 0 {
                status = .won
                feedback = "Victory! The forest imp falls, and the trail toward the princess opens."
                emit(.monsterDefeated)
                return
            }
        case .enemy:
            if isSecondChance {
                let damage = enemyDamage / 2
                playerHP = max(0, playerHP - damage)
                feedback = "Guarded on the second try. Half damage."
                emit(.playerBlock)
            } else {
                feedback = "Perfect dodge. No damage."
                emit(.playerDodge)
            }
        }

        advanceTurn()
    }

    private func resolveFailure() {
        switch actor {
        case .player:
            feedback = "Attack missed. Answer: \(expectedAnswerSummary)"
            emit(.playerMiss)
        case .enemy:
            playerHP = max(0, playerHP - enemyDamage)
            feedback = "No dodge. Answer: \(expectedAnswerSummary)"
            emit(.monsterAttack)

            if playerHP == 0 {
                status = .lost
                feedback = "Defeat. Try the fight again."
                emit(.playerHurt)
                return
            }
        }

        advanceTurn()
    }

    private func advanceTurn() {
        actor = actor == .player ? .enemy : .player
        attempt = 1
        prompt = quizEngine.nextPrompt()

        if prompt.audioPath != nil {
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                playPromptAudio()
            }
        }
    }

    private func emit(_ kind: BattleAnimationKind) {
        animationEvent = BattleAnimationEvent(kind: kind)
    }
}
