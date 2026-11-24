import SwiftUI

struct LeaderboardView: View {
    @Environment(GameCenterManager.self) private var gameCenter
    @State private var scope: GameCenterManager.Scope = .today
    @State private var rows: [GameCenterManager.Row] = []
    @State private var loading = false

    var body: some View {
        NavigationStack {
            List {
                Picker("Period", selection: $scope) {
                    Text("Today").tag(GameCenterManager.Scope.today)
                    Text("Yesterday").tag(GameCenterManager.Scope.yesterday)
                    Text("Best ever").tag(GameCenterManager.Scope.best)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                if !gameCenter.isAuthenticated {
                    Text(gameCenter.statusText).foregroundStyle(.secondary)
                } else if loading && rows.isEmpty {
                    ProgressView()
                } else if rows.isEmpty {
                    Text(scope == .today ? "No scores yet today. Play the daily seven to take first place." : "No scores for this period.")
                        .foregroundStyle(.secondary)
                } else {
                    Section(footer: Text(footer)) {
                        ForEach(rows) { r in
                            HStack {
                                RankBadge(rank: r.rank, medals: scope != .best)
                                Text(r.name + (r.isMe ? " (you)" : "")).fontWeight(r.isMe ? .semibold : .regular)
                                Spacer()
                                Text("\(r.score)").font(.body.monospacedDigit())
                            }
                        }
                    }
                }
                if gameCenter.isAuthenticated {
                    Button("Open in Game Center") { gameCenter.showGameCenterDashboard() }
                }
            }
            .navigationTitle("Leaderboard")
            .task(id: scope) { await reload() }
            .task(id: gameCenter.isAuthenticated) { await reload() }
            .refreshable { await reload() }
        }
    }

    private var footer: String {
        switch scope {
        case .today: "Standings lock at \(DailyPuzzle.nextReset.formatted(date: .omitted, time: .shortened)), when the top three receive medals."
        case .yesterday: "Final standings for yesterday."
        case .best: "Each player's single best daily score."
        }
    }

    private func reload() async {
        loading = true
        rows = await gameCenter.loadRows(scope)
        loading = false
    }
}

struct RankBadge: View {
    let rank: Int
    var medals = true
    var body: some View {
        if medals && rank <= 3 {
            Text("\(rank)").font(.caption.bold().monospaced()).foregroundStyle(.black)
                .frame(width: 24, height: 24).background(Circle().fill(Theme.medal(rank)))
        } else {
            Text("\(rank)").font(.callout.monospacedDigit()).frame(width: 24)
        }
    }
}
