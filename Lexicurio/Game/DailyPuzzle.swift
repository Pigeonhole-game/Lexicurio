import Foundation

/// Everyone gets the same seven words for a UTC day.
enum DailyPuzzle {
    static var utcCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    static func dayKey(_ date: Date = .now) -> String {
        let c = utcCalendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    /// Daily puzzle number, counting from launch day.
    static func number(_ date: Date = .now) -> Int {
        let start = utcCalendar.date(from: DateComponents(year: 2026, month: 11, day: 24))!
        return (utcCalendar.dateComponents([.day], from: start, to: utcCalendar.startOfDay(for: date)).day ?? 0) + 1
    }

    static var nextReset: Date {
        utcCalendar.date(byAdding: .day, value: 1, to: utcCalendar.startOfDay(for: .now))!
    }

    static func words(for day: String) -> [Entry] { pick(seed: "daily-" + day) }
    static func practiceWords() -> [Entry] { pick(seed: "practice-" + UUID().uuidString) }

    private static func pick(seed: String) -> [Entry] {
        var rng = SeededGenerator(seed: seed)
        var pool = WordBank.entries
        var out: [Entry] = []
        while out.count < Scoring.rounds, !pool.isEmpty {
            out.append(pool.remove(at: Int(rng.next() % UInt64(pool.count))))
        }
        return out
    }
}

/// FNV-1a seed + SplitMix64. Deterministic across devices, unlike Swift's Hasher.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: String) {
        var h: UInt64 = 0xcbf29ce484222325
        for b in seed.utf8 { h ^= UInt64(b); h = h &* 0x100000001b3 }
        state = h
    }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
