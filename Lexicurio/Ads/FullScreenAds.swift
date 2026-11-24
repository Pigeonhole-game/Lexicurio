import Observation
import UIKit
import GoogleMobileAds

/// Interstitial shown after a finished game, at most once every 3 minutes.
@MainActor
final class InterstitialController: NSObject, FullScreenContentDelegate {
    private var ad: InterstitialAd?
    private var lastShown = Date.distantPast
    private let minimumGap: TimeInterval = 180

    func load() {
        Task {
            do {
                ad = try await InterstitialAd.load(with: AdUnits.interstitial, request: Request())
                ad?.fullScreenContentDelegate = self
            } catch { print("Interstitial failed to load: \(error.localizedDescription)") }
        }
    }

    func showIfReady() {
        guard Date.now.timeIntervalSince(lastShown) > minimumGap,
              let ad, let vc = UIApplication.topViewController else { return }
        lastShown = .now
        ad.present(from: vc)
    }

    func clear() { ad = nil }

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in self.ad = nil; self.load() }
    }
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in self.ad = nil; self.load() }
    }
}

/// Rewarded ad: watch one to get a hint in a practice game.
@MainActor
@Observable
final class RewardedController: NSObject, FullScreenContentDelegate {
    private var ad: RewardedAd?
    var isReady: Bool { ad != nil }

    func load() {
        Task {
            do {
                ad = try await RewardedAd.load(with: AdUnits.rewarded, request: Request())
                ad?.fullScreenContentDelegate = self
            } catch { print("Rewarded failed to load: \(error.localizedDescription)") }
        }
    }

    func show(onReward: @escaping () -> Void) {
        guard let ad, let vc = UIApplication.topViewController else { return }
        ad.present(from: vc) { onReward() }
    }

    func clear() { ad = nil }

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in self.ad = nil; self.load() }
    }
}

/// App open ad when returning to the app, at most once every 4 hours, never on first launch.
@MainActor
final class AppOpenController: NSObject, FullScreenContentDelegate {
    private var ad: AppOpenAd?
    private var loadedAt = Date.distantPast
    private var lastShown = Date.now          // treat launch as "just shown" so the first open is ad-free
    private var showing = false

    func load() {
        Task {
            do {
                ad = try await AppOpenAd.load(with: AdUnits.appOpen, request: Request())
                ad?.fullScreenContentDelegate = self
                loadedAt = .now
            } catch { print("App open failed to load: \(error.localizedDescription)") }
        }
    }

    func showIfAvailable() {
        guard !showing, let ad,
              Date.now.timeIntervalSince(loadedAt) < 4 * 3600,          // Google: app open ads expire after 4h
              Date.now.timeIntervalSince(lastShown) > 4 * 3600,
              let vc = UIApplication.topViewController else { return }
        showing = true
        lastShown = .now
        ad.present(from: vc)
    }

    func clear() { ad = nil }

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in self.showing = false; self.ad = nil; self.load() }
    }
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in self.showing = false; self.ad = nil; self.load() }
    }
}
