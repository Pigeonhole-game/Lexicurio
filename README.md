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

Pick an iPhone simulator and run. Out of the box the app uses Google's **test** ad units, so you will see "Test Ad" banners, and the local StoreKit file lets you test the Pro purchase in the simulator.

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

1. **AdMob**: create the app and four ad units (banner, interstitial, rewarded, app open) at admob.google.com. Put the IDs in `Lexicurio/Ads/AdUnits.swift` and the app ID in `GADApplicationIdentifier` in `project.yml`. Set up the GDPR and US-state privacy messages in AdMob under Privacy & messaging.
2. **app-ads.txt**: AdMob gives you a line to publish at the root of your developer website. A GitHub Pages user site (`<user>.github.io`) can host it.
3. **App Store Connect**:
   - Bundle ID `com.lexicurio.app` (change in `project.yml` if you prefer another).
   - In-app purchase, non-consumable, product ID `com.lexicurio.app.pro`.
   - Game Center: a **recurring** leaderboard `lexicurio.daily` (high score, 1-day duration, starting 00:00 UTC), a classic leaderboard `lexicurio.best`, and achievements `lexicurio.medal.gold`, `lexicurio.medal.silver`, `lexicurio.medal.bronze`.
   - Privacy "nutrition label": declare data collected by Google AdMob (device ID, usage data, diagnostics, coarse location) used for third-party advertising.
4. **GitHub Pages**: in the repo's Settings > Pages, serve from the `main` branch, `/docs` folder. Use `privacy.html` as the App Store privacy policy URL and `support.html` as the support URL. Update `AppLinks` in `SettingsView.swift` if the URL differs. Add a support email to `support.html`.
5. Replace the placeholder privacy policy wording with text you have reviewed.

## Known limits

- The thesaurus comes from WordNet and accepts some odd matches while missing some expected synonyms. It needs a curation pass.
- Medals: Game Center keeps each daily leaderboard's previous occurrence, so the app awards a medal the next time a top-three player opens it, and shows only that player's own medal cabinet. A shared all-time medal table for every player would need a small backend.
- Not yet compiled: this project was written without access to a Mac, so expect to fix minor compile errors on the first Xcode build.
