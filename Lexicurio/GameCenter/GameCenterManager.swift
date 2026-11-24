import GameKit
import Observation

/// Leaderboard and medals through Game Center.
///
/// App Store Connect setup (see README):
///  - A *recurring* leaderboard `lexicurio.daily`, "High score", duration 1 day, starting 00:00 UTC.
///  - A classic leaderboard `lexicurio.best` for best-ever daily scores.
///  - Achievements `lexicurio.medal.gold`, `lexicurio.medal.silver`, `lexicurio.medal.bronze`.
///
/// Medals: when the app opens, it reads the previous day's occurrence of the daily
/// leaderboard. If the local player finished in the top three, the medal is added to
/// their cabinet and the matching achievement is reported.
@MainActor
@Observable
final class GameCenterManager {
    static let dailyID = "lexicurio.daily"
    static let bestID = "lexicurio.best"
    static let medalAchievement = ["lexicurio.medal.gold", "lexicurio.medal.silver", "lexicurio.medal.bronze"]

    struct Row: Identifiable, Hashable {
        let id: String
        let rank: Int
        let name: String
        let score: Int
        let isMe: Bool
    }
    struct Medal: Codable, Hashable, Identifiable {
        var id: String { day }
        let day: String
        let place: Int
        let score: Int
    }

    private(set) var isAuthenticated = false
    private(set) var playerName = ""
    private(set) var statusText = "Signing in to Game Center…"
    private(set) var podium: [Row] = []          // yesterday's top three
    private(set) var podiumDay: String?
    private(set) var medals: [Medal] = {
        guard let d = UserDefaults.standard.data(forKey: "lx.medals"),
              let m = try? JSONDecoder().decode([Medal].self, from: d) else { return [] }
        return m
    }()

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] vc, error in
            Task { @MainActor in
                guard let self else { return }
                if let vc { UIApplication.topViewController?.present(vc, animated: true); return }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self.playerName = GKLocalPlayer.local.displayName
                if self.isAuthenticated {
                    self.statusText = ""
                    await self.checkMedals()
                } else {
                    self.statusText = "Sign in to Game Center in Settings to join the leaderboard. You can still play."
                    if let error { print("Game Center: \(error.localizedDescription)") }
                }
            }
        }
    }

    func submit(score: Int) async {
        guard isAuthenticated else { return }
        do {
            try await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                                leaderboardIDs: [Self.dailyID, Self.bestID])
        } catch { print("Score submit failed: \(error.localizedDescription)") }
    }

    enum Scope { case today, yesterday, best }

    func loadRows(_ scope: Scope) async -> [Row] {
        guard isAuthenticated else { return [] }
        do {
            let id = scope == .best ? Self.bestID : Self.dailyID
            guard var board = try await GKLeaderboard.loadLeaderboards(IDs: [id]).first else { return [] }
            if scope == .yesterday {
                guard let prev = try await board.loadPreviousOccurrence() else { return [] }
                board = prev
            }
            let (_, entries, _) = try await board.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 50))
            return entries.map { e in
                Row(id: e.player.gamePlayerID, rank: e.rank, name: e.player.displayName, score: e.score,
                    isMe: e.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID)
            }
        } catch {
            print("Leaderboard load failed: \(error.localizedDescription)")
            return []
        }
    }

    func showGameCenterDashboard() {
        let vc = GKGameCenterViewController(leaderboardID: Self.dailyID, playerScope: .global, timeScope: .allTime)
        vc.gameCenterDelegate = DashboardDismisser.shared
        UIApplication.topViewController?.present(vc, animated: true)
    }

    /// Award a medal for the previous day if the player placed in the top three.
    func checkMedals() async {
        guard isAuthenticated else { return }
        do {
            guard let board = try await GKLeaderboard.loadLeaderboards(IDs: [Self.dailyID]).first,
                  let prev = try await board.loadPreviousOccurrence() else { return }
            let (mine, top, _) = try await prev.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 3))
            let day = prev.startDate.map { DailyPuzzle.dayKey($0) } ?? DailyPuzzle.dayKey(.now.addingTimeInterval(-86_400))
            podiumDay = day
            podium = top.map { Row(id: $0.player.gamePlayerID, rank: $0.rank, name: $0.player.displayName, score: $0.score,
                                    isMe: $0.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID) }
            if let mine, (1...3).contains(mine.rank), !medals.contains(where: { $0.day == day }) {
                medals.insert(Medal(day: day, place: mine.rank, score: mine.score), at: 0)
                if let data = try? JSONEncoder().encode(medals) { UserDefaults.standard.set(data, forKey: "lx.medals") }
                let a = GKAchievement(identifier: Self.medalAchievement[mine.rank - 1])
                a.percentComplete = 100
                a.showsCompletionBanner = true
                try? await GKAchievement.report([a])
            }
        } catch {
            print("Medal check failed: \(error.localizedDescription)")
        }
    }

    func count(place: Int) -> Int { medals.filter { $0.place == place }.count }
}

final class DashboardDismisser: NSObject, GKGameCenterControllerDelegate {
    static let shared = DashboardDismisser()
    func gameCenterViewControllerDidFinish(_ vc: GKGameCenterViewController) { vc.dismiss(animated: true) }
}
