import Foundation

/// One headword and its accepted synonyms. Each synonym carries a Zipf frequency:
/// roughly log10 of how often it appears per billion words (6 = everyday, 1 = very rare).
struct Entry: Decodable, Hashable {
    let word: String
    let partOfSpeech: String
    let synonyms: [String: Double]

    enum CodingKeys: String, CodingKey { case word = "w", partOfSpeech = "pos", synonyms = "syn" }

    var partOfSpeechName: String {
        switch partOfSpeech { case "a": "adjective"; case "v": "verb"; default: "noun" }
    }

    /// The rarest accepted synonyms, rarest first.
    func rarest(_ n: Int) -> [(word: String, points: Int)] {
        synonyms.sorted { $0.value < $1.value }.prefix(n).map { ($0.key, Scoring.points(zipf: $0.value)) }
    }
}

enum WordBank {
    static let entries: [Entry] = {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return list.sorted { $0.word < $1.word }
    }()
}

enum Scoring {
    static let rounds = 7
    static let maxPerRound = 100

    /// 10 points for an everyday word, rising to 100 for an eclectic one.
    static func points(zipf: Double) -> Int {
        max(10, min(maxPerRound, Int((10 + (5.5 - zipf) * 20).rounded())))
    }

    static func tier(_ points: Int) -> String {
        switch points {
        case 80...: "Eclectic"
        case 55...: "Rare"
        case 30...: "Uncommon"
        default: "Common"
        }
    }

    enum Verdict: Equatable { case scored(Int, zipf: Double), sameWord, notListed, invalid }

    static func judge(_ raw: String, for entry: Entry) -> Verdict {
        let guess = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !guess.isEmpty, guess.allSatisfy({ $0.isLetter && $0.isASCII }) else { return .invalid }
        if guess == entry.word { return .sameWord }
        if let z = entry.synonyms[guess] { return .scored(points(zipf: z), zipf: z) }
        return .notListed
    }
}
