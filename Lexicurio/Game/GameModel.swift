import Foundation
import Observation

struct Answer: Identifiable, Codable, Hashable {
    var id: Int { round }
    let round: Int
    let headword: String
    let guess: String
    let points: Int
    let zipf: Double?
    let note: String?
}

@Observable
final class GameModel {
    enum Phase: Equatable { case intro, round, result, final }

    private(set) var phase: Phase = .intro
    private(set) var ranked = true
    private(set) var day = DailyPuzzle.dayKey()
    private(set) var words: [Entry] = []
    private(set) var index = 0
    private(set) var answers: [Answer] = []
    var hint: String?

    var current: Entry? { words.indices.contains(index) ? words[index] : nil }
    var total: Int { answers.reduce(0) { $0 + $1.points } }
    var lastAnswer: Answer? { answers.last }

    private let defaults = UserDefaults.standard
    func rankedScore(for day: String) -> Int? {
        defaults.object(forKey: "lx.done.\(day)") as? Int
    }
    var playedToday: Bool { rankedScore(for: DailyPuzzle.dayKey()) != nil }

    func start() {
        day = DailyPuzzle.dayKey()
        ranked = !playedToday
        words = ranked ? DailyPuzzle.words(for: day) : DailyPuzzle.practiceWords()
        index = 0; answers = []; hint = nil
        phase = .round
    }

    func startPractice() {
        ranked = false
        words = DailyPuzzle.practiceWords()
        index = 0; answers = []; hint = nil
        phase = .round
    }

    /// Returns an error message to show without using up the round, or nil when the guess was locked in.
    @discardableResult
    func submit(_ text: String) -> String? {
        guard let entry = current else { return nil }
        let guess = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch Scoring.judge(text, for: entry) {
        case .invalid:
            return "Use a single word with letters only."
        case .sameWord:
            answers.append(Answer(round: index, headword: entry.word, guess: guess, points: 0, zipf: nil, note: "That is the word itself."))
        case .notListed:
            answers.append(Answer(round: index, headword: entry.word, guess: guess, points: 0, zipf: nil, note: "“\(guess)” is not listed as a synonym of \(entry.word)."))
        case let .scored(p, z):
            answers.append(Answer(round: index, headword: entry.word, guess: guess, points: p, zipf: z, note: nil))
        }
        hint = nil
        phase = .result
        return nil
    }

    /// Advances; returns true when the game just finished.
    func next() -> Bool {
        if index >= Scoring.rounds - 1 {
            phase = .final
            if ranked { defaults.set(total, forKey: "lx.done.\(day)") }
            return true
        }
        index += 1
        phase = .round
        return false
    }

    func backToIntro() { phase = .intro }

    /// A hint for practice games: first letter and length of the rarest synonym.
    func revealHint() {
        guard let entry = current, let rare = entry.rarest(1).first else { return }
        hint = "Starts with “\(rare.word.prefix(1).uppercased())”, \(rare.word.count) letters, worth \(rare.points)."
    }
}
