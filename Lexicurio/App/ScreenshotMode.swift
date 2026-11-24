#if DEBUG
import Foundation

/// DEBUG-only App Store screenshot mode. Launch with:
///   -screenshots -screenshotTab <0-3> -screenshotScene <intro|round|result|final>
/// Ads, StoreKit and Game Center sign-in are skipped; the game and Game Center
/// tabs are seeded with demo state.
enum ScreenshotMode {
    static let isOn = ProcessInfo.processInfo.arguments.contains("-screenshots")
    static var tab: Int { UserDefaults.standard.integer(forKey: "screenshotTab") }
    static var scene: String { UserDefaults.standard.string(forKey: "screenshotScene") ?? "intro" }
    /// Lexicurio Pro price shown on Settings (StoreKit is skipped); matches Lexicurio.storekit.
    static let proPrice = "$2.99"
    /// Text pre-typed into the round's answer field.
    static var prefill: String? { isOn && scene == "round" ? demoGuess(roundIndex: 3) : nil }

    /// Varied picks from each word's synonyms, rarest first, so scores span the tiers.
    static let pickOrder = [1, 4, 0, 6, 2, 8, 3]

    static func demoGuess(roundIndex i: Int) -> String? {
        let words = DailyPuzzle.words(for: DailyPuzzle.dayKey())
        guard words.indices.contains(i) else { return nil }
        let syns = words[i].synonyms.sorted { $0.value < $1.value }.map(\.key)
        guard !syns.isEmpty else { return nil }
        return syns[min(pickOrder[i], syns.count - 1)]
    }
}
#endif
