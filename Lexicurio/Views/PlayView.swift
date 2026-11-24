import SwiftUI

struct PlayView: View {
    @State private var game = GameModel()
    @Environment(AdsManager.self) private var ads
    @Environment(StoreManager.self) private var store
    @Environment(GameCenterManager.self) private var gameCenter

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if game.phase != .intro { RackView(game: game) }
                    switch game.phase {
                    case .intro: IntroCard(game: game)
                    case .round: RoundCard(game: game)
                    case .result: ResultCard(game: game, onNext: advance)
                    case .final: FinalCard(game: game)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Lexicurio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("No. \(DailyPuzzle.number())").font(.caption.monospaced()).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func advance() {
        guard game.next() else { return }
        if game.ranked { Task { await gameCenter.submit(score: game.total) } }
        ads.gameFinished()
    }
}

private struct RackView: View {
    let game: GameModel
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<Scoring.rounds, id: \.self) { i in
                let a = game.answers.first { $0.round == i }
                let now = game.phase == .round && i == game.index
                VStack(spacing: 2) {
                    Text("\(i + 1)").font(.caption2.monospaced()).foregroundStyle(.secondary)
                    Text(a?.guess ?? (now ? game.words[i].word : " "))
                        .font(.caption2.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.6)
                    Text(a.map { "\($0.points)" } ?? " ")
                        .font(.caption.monospaced()).foregroundStyle(a?.points == 0 ? .red : .primary)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color(.secondarySystemGroupedBackground)))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(now ? Theme.accent : Color(.separator), lineWidth: now ? 2 : 0.5))
            }
        }
    }
}

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemGroupedBackground)))
    }
}

private struct IntroCard: View {
    let game: GameModel
    var body: some View {
        Card {
            Text("HOW TO PLAY").font(.caption.weight(.semibold)).tracking(1).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Text("1. You get seven common words, the same seven for everyone today.")
                Text("2. Type one synonym for each. Rarer words score more: a stock synonym earns about 10 points, an eclectic one up to 100.")
                Text("3. Your seven scores add up to your final score. The day's top three win gold, silver and bronze.")
            }.font(.callout)
            if let score = game.rankedScore(for: DailyPuzzle.dayKey()) {
                Text("You scored \(score) in today's ranked game. Practice games use random words and don't count.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Practice round") { game.startPractice() }.buttonStyle(.borderedProminent)
            } else {
                Button("Start today’s seven") { game.start() }.buttonStyle(.borderedProminent)
            }
            Text("New words every day at \(DailyPuzzle.nextReset.formatted(date: .omitted, time: .shortened)).")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct RoundCard: View {
    let game: GameModel
    @State private var text = ""
    @State private var error: String?
    @FocusState private var focused: Bool
    @Environment(AdsManager.self) private var ads
    @Environment(StoreManager.self) private var store

    var body: some View {
        if let entry = game.current {
            Card {
                HStack {
                    Text("ROUND \(game.index + 1) OF \(Scoring.rounds)\(game.ranked ? "" : " · PRACTICE")")
                    Spacer()
                    Text("TOTAL \(game.total)")
                }.font(.caption.monospaced()).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.word).font(.system(size: 52, weight: .heavy, design: .rounded)).minimumScaleFactor(0.5)
                    Text(entry.partOfSpeechName).font(.subheadline.monospaced()).foregroundStyle(Theme.brass)
                }
                TextField("A synonym for \(entry.word)", text: $text)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .font(.title3).padding(12)
                    .background(RoundedRectangle(cornerRadius: 6).stroke(Color(.separator)))
                    .focused($focused).submitLabel(.done)
                    .onSubmit(lockIn)
                Button("Lock it in", action: lockIn).buttonStyle(.borderedProminent)
                if let error { Text(error).font(.footnote).foregroundStyle(.red) }
                else { Text("One word only. You get one try per round.").font(.footnote).foregroundStyle(.secondary) }

                if !game.ranked {
                    if let hint = game.hint {
                        Label(hint, systemImage: "lightbulb").font(.footnote)
                    } else if store.isAdFree {
                        Button("Show a hint") { game.revealHint() }.font(.footnote)
                    } else if ads.canShowAds && ads.rewarded.isReady {
                        Button { ads.rewarded.show { game.revealHint() } } label: {
                            Label("Watch an ad for a hint", systemImage: "play.rectangle")
                        }.font(.footnote)
                    }
                }
            }
            .onAppear { text = ""; error = nil; focused = true }
            .id(game.index)
        }
    }

    private func lockIn() {
        error = game.submit(text)
    }
}

private struct ResultCard: View {
    let game: GameModel
    let onNext: () -> Void
    var body: some View {
        if let a = game.lastAnswer, let entry = WordBank.entries.first(where: { $0.word == a.headword }) {
            Card {
                Text("ROUND \(a.round + 1) · \(a.headword.uppercased())").font(.caption.monospaced()).foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline) {
                    Text("+\(a.points)").font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(a.points == 0 ? .red : .primary)
                    if a.points > 0 {
                        Text(Scoring.tier(a.points).uppercased()).font(.caption.weight(.semibold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .overlay(Capsule().stroke(Theme.brass)).foregroundStyle(Theme.brass)
                    }
                }
                if let z = a.zipf {
                    RarityScale(zipf: z)
                    Text("“\(a.guess)” turns up about \(Self.frequency(z)) in ordinary English.").font(.footnote).foregroundStyle(.secondary)
                } else if let note = a.note {
                    Text(note).font(.footnote).foregroundStyle(.red)
                }
                Text("Rarest finds for \(entry.word): " + entry.rarest(3).map { "\($0.word) (\($0.points))" }.joined(separator: ", "))
                    .font(.footnote).foregroundStyle(.secondary)
                Button(a.round == Scoring.rounds - 1 ? "See final score" : "Next word", action: onNext)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    static func frequency(_ z: Double) -> String {
        let perMillion = pow(10, z) / 1000
        if perMillion >= 1 { return "\(Int(perMillion.rounded())) times per million words" }
        let per100M = perMillion * 100
        return per100M >= 1 ? "\(Int(per100M.rounded())) times per 100 million words" : "less than once per 100 million words"
    }
}

private struct RarityScale: View {
    let zipf: Double
    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(LinearGradient(colors: [Color(.systemGray4), Theme.accent], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 2).fill(.primary).frame(width: 4, height: 16)
                        .offset(x: geo.size.width * max(0.02, min(0.98, (6 - zipf) / 5)) - 2)
                }.frame(maxHeight: .infinity)
            }.frame(height: 16)
            HStack { Text("everyday"); Spacer(); Text("eclectic") }.font(.caption2).foregroundStyle(.secondary)
        }
    }
}

private struct FinalCard: View {
    let game: GameModel
    @Environment(GameCenterManager.self) private var gameCenter
    var body: some View {
        Card {
            Text(game.ranked ? "FINAL SCORE · DAILY NO. \(DailyPuzzle.number())" : "PRACTICE SCORE")
                .font(.caption.monospaced()).foregroundStyle(.secondary)
            Text("\(game.total)").font(.system(size: 72, weight: .heavy, design: .rounded))
            Text("out of a possible \(Scoring.rounds * Scoring.maxPerRound).").font(.footnote).foregroundStyle(.secondary)
            if let best = game.answers.max(by: { $0.points < $1.points }), best.points > 0 {
                Text("Best word: **\(best.guess)** for \(best.points).").font(.callout)
            }
            Text(game.ranked
                 ? (gameCenter.isAuthenticated ? "Your score is on today's Game Center leaderboard." : gameCenter.statusText)
                 : "Practice games are not ranked.")
                .font(.footnote).foregroundStyle(.secondary)
            HStack {
                Button("Practice round") { game.startPractice() }.buttonStyle(.borderedProminent)
                Button("Done") { game.backToIntro() }.buttonStyle(.bordered)
            }
        }
    }
}
