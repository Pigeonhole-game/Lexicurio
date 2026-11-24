import SwiftUI

struct SettingsView: View {
    @Environment(StoreManager.self) private var store
    @Environment(AdsManager.self) private var ads

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if store.isAdFree {
                        Label("Lexicurio Pro is active. No ads, free hints.", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Theme.accent)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Lexicurio Pro").font(.headline)
                            Text("A one-time purchase that removes every ad and makes practice hints free.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        Button {
                            Task { await store.buy() }
                        } label: {
                            Text(store.pro.map { "Go ad-free for \($0.displayPrice)" } ?? "Go ad-free")
                        }
                        .disabled(store.pro == nil || store.purchaseInFlight)
                    }
                    Button("Restore purchases") { Task { await store.restore() } }
                    if let msg = store.message { Text(msg).font(.footnote).foregroundStyle(.secondary) }
                } header: { Text("Ad-free") }

                if ads.privacyOptionsRequired {
                    Section("Privacy") {
                        Button("Ad privacy choices") { Task { await ads.showPrivacyOptions() } }
                    }
                }

                Section("About") {
                    Link("Privacy policy", destination: AppLinks.privacy)
                    Link("Support", destination: AppLinks.support)
                    Text("Synonyms from WordNet (Princeton University). Word frequencies from wordfreq.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

/// The GitHub Pages site in /docs. Update if the repository or owner name changes.
enum AppLinks {
    static let site = "https://pigeonhole-game.github.io/Lexicurio"
    static let privacy = URL(string: site + "/privacy.html")!
    static let support = URL(string: site + "/support.html")!
}
