import SwiftUI

@main
struct LexicurioApp: App {
    @State private var store = StoreManager()
    @State private var ads = AdsManager()
    @State private var gameCenter = GameCenterManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(ads)
                .environment(gameCenter)
                .task {
                    #if DEBUG
                    if ScreenshotMode.isOn { gameCenter.seedForScreenshots(); return }
                    #endif
                    await store.start()
                    ads.isAdFree = store.isAdFree
                    await ads.startIfAllowed()
                    gameCenter.authenticate()
                }
                .onChange(of: store.isAdFree) { _, adFree in ads.isAdFree = adFree }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active && ads.canShowAds { ads.appOpen.showIfAvailable() }
                }
        }
    }
}
