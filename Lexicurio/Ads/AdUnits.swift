import Foundation

/// AdMob ad unit IDs. These are Google's public TEST units, which always serve test ads.
/// Replace each with your own unit from the AdMob console before release
/// (and the GADApplicationIdentifier in project.yml / Info.plist).
enum AdUnits {
    static let banner       = "ca-app-pub-3940256099942544/2435281174" // adaptive banner (test)
    static let interstitial = "ca-app-pub-3940256099942544/4411468910" // interstitial (test)
    static let rewarded     = "ca-app-pub-3940256099942544/1712485313" // rewarded (test)
    static let appOpen      = "ca-app-pub-3940256099942544/5575463023" // app open (test)
}
