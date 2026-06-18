import Foundation

struct QuizEngine {
    let vocabulary: Vocabulary

    func nextPrompt() -> QuizPrompt {
        let items = vocabulary.items.isEmpty ? VocabularyLoader.load().items : vocabulary.items
        let item = items.randomElement() ?? VocabItem(
            id: "hola",
            kind: .word,
            spanish: "hola",
            english: ["hello"],
            audio: nil
        )
        let mode = availableModes(for: item).randomElement() ?? .spanishToEnglish

        switch mode {
        case .spanishToEnglish:
            let answer = item.english.first ?? ""
            return QuizPrompt(
                item: item,
                mode: mode,
                question: item.spanish,
                acceptedAnswers: item.english,
                choices: choices(correct: answer, pool: items.flatMap(\.english))
            )
        case .englishToSpanish:
            return QuizPrompt(
                item: item,
                mode: mode,
                question: item.english.first ?? item.spanish,
                acceptedAnswers: [item.spanish],
                choices: choices(correct: item.spanish, pool: items.map(\.spanish))
            )
        case .audioToSpanish:
            return QuizPrompt(
                item: item,
                mode: mode,
                question: "Tap the speaker, then choose what you hear.",
                acceptedAnswers: [item.spanish],
                choices: choices(correct: item.spanish, pool: items.map(\.spanish))
            )
        }
    }

    private func availableModes(for item: VocabItem) -> [DrillMode] {
        var modes: [DrillMode] = [.spanishToEnglish, .englishToSpanish]
        if item.audio != nil {
            modes.append(.audioToSpanish)
        }
        return modes
    }

    private func choices(correct: String, pool: [String]) -> [String] {
        let normalizedCorrect = QuizPrompt.normalize(correct)
        var options = pool
            .filter { QuizPrompt.normalize($0) != normalizedCorrect }
            .shuffled()

        options.insert(correct, at: 0)
        return Array(options.prefix(4)).shuffled()
    }
}
