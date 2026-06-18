import Foundation

enum DrillMode: CaseIterable {
    case spanishToEnglish
    case englishToSpanish
    case audioToSpanish

    var title: String {
        switch self {
        case .spanishToEnglish:
            "Translate to English"
        case .englishToSpanish:
            "Translate to Spanish"
        case .audioToSpanish:
            "Listen and choose Spanish"
        }
    }
}

struct QuizPrompt: Identifiable {
    let id = UUID()
    let item: VocabItem
    let mode: DrillMode
    let question: String
    let acceptedAnswers: [String]
    let choices: [String]

    var audioPath: String? {
        mode == .audioToSpanish ? item.audio : nil
    }

    func accepts(_ answer: String) -> Bool {
        let normalizedAnswer = Self.normalize(answer)
        return acceptedAnswers.contains { Self.normalize($0) == normalizedAnswer }
    }

    static func normalize(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,!?¡¿"))
            .lowercased()
    }
}
