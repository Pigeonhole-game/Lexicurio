# Lexicurio

An iOS word game. Each day everyone gets the same seven common words and types one synonym for each. Rarer, more eclectic synonyms score more points (10 to 100 per word, 700 max). Scores go on a daily Game Center leaderboard, and the day's top three players win gold, silver and bronze medals.

Free with Google AdMob ads, or ad-free with a one-time **Lexicurio Pro** purchase.

## Project layout

| Path | What it is |
|---|---|
| `project.yml` | XcodeGen spec. Generates `Lexicurio.xcodeproj` with the Google SDKs added through Swift Package Manager. |
| `Lexicurio/Game` | Word bank, scoring, the seeded daily puzzle and the game state. |
| `Lexicurio/Views` | SwiftUI screens: Play, Leaderboard, Medals, Settings. |
| `Lexicurio/Ads` | AdMob: consent (UMP), App Tracking Transparency, banner, interstitial, rewarded and app open ads. |
| `Lexicurio/Store` | StoreKit 2 purchase of Lexicurio Pro, plus a local `.storekit` file for testing without App Store Connect. |
| `Lexicurio/GameCenter` | Daily leaderboard, best-ever leaderboard, and medal awarding. |
| `Lexicurio/Resources/words.json` | 63 headwords with synonyms and word-frequency scores. |
| `tools/build_words.py` | Regenerates `words.json` from WordNet and wordfreq. |
| `docs/` | GitHub Pages site: home, privacy policy, support. |

## Build and run (Mac with Xcode 15 or later)

```sh
brew install xcodegen
xcodegen
open Lexicurio.xcodeproj
```

Pick an iPhone simulator and run. Debug builds use Google's **test** ad units, so you will see "Test Ad" banners and never click your own live ads. Release builds use the real Lexicurio ad units. The local StoreKit file lets you test the Pro purchase in the simulator.

## Scoring

Each synonym has a Zipf frequency (about log10 of occurrences per billion words). Points = `10 + (5.5 − zipf) × 20`, clamped to 10–100. For example: *glad* 22, *stroll* 49, *halcyon* 67, *doleful* 82, *riant* 96.

## How ads work

| Format | Where | Limits |
|---|---|---|
| Adaptive banner | Under the tab bar | Hidden for Pro |
| Interstitial | After a finished game | At most once every 3 minutes |
| Rewarded | "Watch an ad for a hint" in practice games only, so ranked play stays fair | Pro gets hints free |
| App open | When returning to the app | At most once every 4 hours, never on first launch |

At launch the app shows Google's consent form where required (GDPR and US state laws), then the iOS tracking prompt, and only then starts the Mobile Ads SDK. Players who buy Pro never load an ad.

## Before App Store release

1. **AdMob**: done. The Lexicurio iOS app and its four ad units (banner, interstitial, rewarded, app open) exist in AdMob, and their IDs are in `Lexicurio/Ads/AdUnits.swift` and `project.yml`. Still to do: in AdMob under Privacy & messaging, create the GDPR and US-state messages for Lexicurio, and once the app is live, add its App Store listing in AdMob so Google can review it and lift the "limited ad serving" state.
2. **app-ads.txt**: publish this line at the root of the developer website you list in App Store Connect (for example a `<user>.github.io` site): `google.com, pub-8750404699725798, DIRECT, f08c47fec0942fa0`. A copy is in `docs/app-ads.txt`.
3. **App Store Connect**:
   - Bundle ID `com.lexicurio.app` (change in `project.yml` if you prefer another).
   - In-app purchase, non-consumable, product ID `com.lexicurio.app.pro`.
   - Game Center: a **recurring** leaderboard `lexicurio.daily` (high score, 1-day duration, starting 00:00 UTC), a classic leaderboard `lexicurio.best`, and achievements `lexicurio.medal.gold`, `lexicurio.medal.silver`, `lexicurio.medal.bronze`.
   - Privacy "nutrition label": declare data collected by Google AdMob (device ID, usage data, diagnostics, coarse location) used for third-party advertising.
4. **GitHub Pages**: in the repo's Settings > Pages, serve from the `main` branch, `/docs` folder. Use `privacy.html` as the App Store privacy policy URL and `support.html` as the support URL. Update `AppLinks` in `SettingsView.swift` if the URL differs.

## Known limits

- The thesaurus comes from WordNet and accepts some odd matches while missing some expected synonyms. It needs a curation pass.
- Medals: Game Center keeps each daily leaderboard's previous occurrence, so the app awards a medal the next time a top-three player opens it, and shows only that player's own medal cabinet. A shared all-time medal table for every player would need a small backend.
- Verified 2026-11-24: Debug and Release simulator builds succeed with Xcode 27.2, GoogleMobileAds 12.14.0 and UMP 3.1.0.
