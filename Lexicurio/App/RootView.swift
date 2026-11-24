import SwiftUI

struct RootView: View {
    @Environment(AdsManager.self) private var ads
    @State private var tab: Int = {
        #if DEBUG
        if ScreenshotMode.isOn { return ScreenshotMode.tab }
        #endif
        return 0
    }()

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $tab) {
                PlayView()
                    .tabItem { Label("Play", systemImage: "character.book.closed") }.tag(0)
                LeaderboardView()
                    .tabItem { Label("Leaderboard", systemImage: "list.number") }.tag(1)
                MedalsView()
                    .tabItem { Label("Medals", systemImage: "medal") }.tag(2)
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }.tag(3)
            }
            if ads.canShowAds {
                BannerAdView()
                    .frame(height: 50)
                    .accessibilityLabel("Advertisement")
            }
        }
        .tint(Theme.accent)
    }
}

enum Theme {
    static let accent = Color(red: 0.12, green: 0.31, blue: 0.55)
    static let brass = Color(red: 0.66, green: 0.45, blue: 0.10)
    static let gold = Color(red: 0.79, green: 0.59, blue: 0.11)
    static let silver = Color(red: 0.56, green: 0.60, blue: 0.65)
    static let bronze = Color(red: 0.63, green: 0.38, blue: 0.18)
    static func medal(_ place: Int) -> Color { [gold, silver, bronze][max(0, min(2, place - 1))] }
}
