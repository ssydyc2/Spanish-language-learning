import Foundation

enum VocabularyLoader {
    static func load() -> Vocabulary {
        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json") else {
            return fallbackVocabulary()
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Vocabulary.self, from: data)
        } catch {
            return fallbackVocabulary()
        }
    }

    private static func fallbackVocabulary() -> Vocabulary {
        Vocabulary(
            version: 1,
            items: [
                VocabItem(
                    id: "hola",
                    kind: .word,
                    spanish: "hola",
                    english: ["hello", "hi"],
                    audio: nil
                ),
                VocabItem(
                    id: "buenos_dias",
                    kind: .sentence,
                    spanish: "buenos dias",
                    english: ["good morning"],
                    audio: nil
                )
            ]
        )
    }
}
