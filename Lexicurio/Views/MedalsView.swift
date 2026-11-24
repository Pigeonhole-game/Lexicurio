import SwiftUI

struct MedalsView: View {
    @Environment(GameCenterManager.self) private var gameCenter

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        ForEach(1...3, id: \.self) { place in
                            VStack(spacing: 6) {
                                Image(systemName: "medal.fill").font(.largeTitle).foregroundStyle(Theme.medal(place))
                                Text("\(gameCenter.count(place: place))").font(.title2.bold().monospacedDigit())
                                Text(["Gold", "Silver", "Bronze"][place - 1]).font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity)
                        }
                    }.padding(.vertical, 8)
                } header: { Text("Your cabinet") } footer: {
                    Text("The top three scores each day win gold, silver and bronze. Medals are awarded when the day closes at \(DailyPuzzle.nextReset.formatted(date: .omitted, time: .shortened)).")
                }

                Section("Yesterday's podium") {
                    if gameCenter.podium.isEmpty {
                        Text(gameCenter.isAuthenticated ? "No podium yet." : gameCenter.statusText).foregroundStyle(.secondary)
                    }
                    ForEach(gameCenter.podium) { r in
                        HStack {
                            RankBadge(rank: r.rank)
                            Text(r.name + (r.isMe ? " (you)" : ""))
                            Spacer()
                            Text("\(r.score)").monospacedDigit()
                        }
                    }
                }

                if !gameCenter.medals.isEmpty {
                    Section("Your medals") {
                        ForEach(gameCenter.medals) { m in
                            HStack {
                                RankBadge(rank: m.place)
                                Text(m.day).font(.callout.monospaced())
                                Spacer()
                                Text("\(m.score)").monospacedDigit()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Medals")
            .refreshable { await gameCenter.checkMedals() }
        }
    }
}
