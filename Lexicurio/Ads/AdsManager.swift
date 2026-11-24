import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency

/// Owns consent, SDK start-up and the full-screen ad formats.
/// Nothing loads or shows while the player owns Lexicurio Pro.
@MainActor
@Observable
final class AdsManager {
    var isAdFree = false {
        didSet { if isAdFree { interstitial.clear(); rewarded.clear(); appOpen.clear() } }
    }
    private(set) var sdkStarted = false
    private(set) var privacyOptionsRequired = false

    let interstitial = InterstitialController()
    let rewarded = RewardedController()
    let appOpen = AppOpenController()

    var canShowAds: Bool { sdkStarted && !isAdFree }

    /// 1. Ask for GDPR/US-state consent through Google's UMP form when required.
    /// 2. Ask for App Tracking Transparency.
    /// 3. Start the Mobile Ads SDK only if consent allows requesting ads.
    func startIfAllowed() async {
        guard !isAdFree, !sdkStarted else { return }
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            if let vc = UIApplication.topViewController {
                try await ConsentForm.loadAndPresentIfRequired(from: vc)
            }
        } catch {
            print("Consent error: \(error.localizedDescription)")
        }
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        guard ConsentInformation.shared.canRequestAds else { return }

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        _ = await MobileAds.shared.start()
        sdkStarted = true
        guard !isAdFree else { return }
        interstitial.load()
        rewarded.load()
        appOpen.load()
    }

    func showPrivacyOptions() async {
        guard let vc = UIApplication.topViewController else { return }
        try? await ConsentForm.presentPrivacyOptionsForm(from: vc)
    }

    /// Called when a game ends.
    func gameFinished() {
        guard canShowAds else { return }
        interstitial.showIfReady()
    }
}

extension UIApplication {
    static var topViewController: UIViewController? {
        let scene = shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
            ?? shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var vc = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        return vc
    }
}
