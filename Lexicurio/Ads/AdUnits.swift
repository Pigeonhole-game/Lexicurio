import Foundation

/// AdMob ad unit IDs for the Lexicurio app (AdMob app ID ca-app-pub-8750404699725798~7194480102).
///
/// Debug builds use Google's public test units so you never click your own live ads,
/// which AdMob treats as invalid traffic. Release builds use the real units.
enum AdUnits {
    #if DEBUG
    static let banner       = "ca-app-pub-3940256099942544/2435281174" // Google test: adaptive banner
    static let interstitial = "ca-app-pub-3940256099942544/4411468910" // Google test: interstitial
    static let rewarded     = "ca-app-pub-3940256099942544/1712485313" // Google test: rewarded
    static let appOpen      = "ca-app-pub-3940256099942544/5575463023" // Google test: app open
    #else
    static let banner       = "ca-app-pub-8750404699725798/6316512709" // Lexicurio Banner
    static let interstitial = "ca-app-pub-8750404699725798/9452017322" // Lexicurio Interstitial
    static let rewarded     = "ca-app-pub-8750404699725798/2848040988" // Lexicurio Rewarded Hint
    static let appOpen      = "ca-app-pub-8750404699725798/1793019156" // Lexicurio App Open
    #endif
}
