import Foundation

struct Vocabulary: Decodable {
    let version: Int
    let items: [VocabItem]
}

struct VocabItem: Decodable, Identifiable {
    let id: String
    let kind: ItemKind
    let spanish: String
    let english: [String]
    let audio: String?
}

enum ItemKind: String, Decodable {
    case word
    case sentence
}
