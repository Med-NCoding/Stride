import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Reference Photo Theme Palette & Components
// ─────────────────────────────────────────────────────────────────────────────
private struct ReferenceTheme {
    static let bgTop = Color(red: 0.26, green: 0.34, blue: 0.38)
    static let bgBottom = Color(red: 0.12, green: 0.16, blue: 0.20)
    static let tealStart = Color(red: 0.22, green: 0.68, blue: 0.74)
    static let tealEnd = Color(red: 0.12, green: 0.48, blue: 0.55)
    static let tealGradient = LinearGradient(
        colors: [tealStart, tealEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let glassCardBg = Color.black.opacity(0.32)
    static let glassBorder = Color.white.opacity(0.18)
    static let textPrimary = Color.white
    static let textMuted = Color.white.opacity(0.65)
}

struct ChallengesView: View {
    @State private var showCreateSheet = false
    @State private var opponent        = ""
    @State private var wager           = ""

    var body: some View {
        ZStack {
            // Atmospheric background matching reference photo
            LinearGradient(
                colors: [ReferenceTheme.bgTop, ReferenceTheme.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ambient warm glow bokeh
            Circle()
                .fill(Color(red: 1.0, green: 0.62, blue: 0.30).opacity(0.35))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: 110, y: -100)

            // Secondary cool teal glow
            Circle()
                .fill(ReferenceTheme.tealStart.opacity(0.20))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -120, y: 180)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    activeChallengesSection
                    historySection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .sheet(isPresented: $showCreateSheet) { createChallengeSheet }
    }

    // MARK: Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Challenges")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ReferenceTheme.textPrimary)
                Text("1-on-1 step battles")
                    .font(.system(size: 14))
                    .foregroundColor(ReferenceTheme.textMuted)
            }
            Spacer()
            Button { showCreateSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("New")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(ReferenceTheme.tealGradient))
                .shadow(color: ReferenceTheme.tealStart.opacity(0.4), radius: 6, x: 0, y: 3)
            }
        }
    }

    // MARK: Active Challenges
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIVE BATTLES")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ReferenceTheme.textMuted)
                    .tracking(0.8)
                Spacer()
            }

            VStack(spacing: 12) {
                customChallengeCard(
                    you: "You",
                    opponent: "Alice",
                    yourSteps: 10400,
                    opponentSteps: 8900,
                    wager: 50,
                    hoursLeft: 4
                )
                customChallengeCard(
                    you: "You",
                    opponent: "Charlie",
                    yourSteps: 5200,
                    opponentSteps: 6100,
                    wager: 20,
                    hoursLeft: 48
                )
            }
        }
    }

    private func customChallengeCard(you: String, opponent: String, yourSteps: Int, opponentSteps: Int, wager: Int, hoursLeft: Int) -> some View {
        let total = Double(yourSteps + opponentSteps)
        let yourRatio = total > 0 ? Double(yourSteps) / total : 0.5
        let isWinning = yourSteps >= opponentSteps

        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(you) vs \(opponent)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ReferenceTheme.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("\(hoursLeft)h left")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(ReferenceTheme.textMuted)
                }
                Spacer()
                // Wager badge
                HStack(spacing: 4) {
                    Text("₿ \(wager)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(ReferenceTheme.tealGradient))
            }

            // Progress bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ReferenceTheme.tealGradient)
                            .frame(width: geo.size.width * CGFloat(yourRatio), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(ReferenceTheme.tealStart).frame(width: 7, height: 7)
                        Text(yourSteps >= 1000 ? String(format: "%.1fk", Double(yourSteps)/1000) : "\(yourSteps)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ReferenceTheme.textPrimary)
                        Text("you")
                            .font(.system(size: 11))
                            .foregroundColor(ReferenceTheme.textMuted)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text(opponent)
                            .font(.system(size: 11))
                            .foregroundColor(ReferenceTheme.textMuted)
                        Text(opponentSteps >= 1000 ? String(format: "%.1fk", Double(opponentSteps)/1000) : "\(opponentSteps)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ReferenceTheme.textMuted)
                        Circle().fill(Color.white.opacity(0.2)).frame(width: 7, height: 7)
                    }
                }
            }

            // Status pill
            HStack(spacing: 6) {
                Circle()
                    .fill(isWinning ? SD.success : SD.danger)
                    .frame(width: 7, height: 7)
                Text(isWinning ? "You're leading" : "Opponent is ahead")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isWinning ? SD.success : SD.danger)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ReferenceTheme.glassCardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(ReferenceTheme.glassBorder, lineWidth: 1)
                )
        )
    }

    // MARK: History
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT RESULTS")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ReferenceTheme.textMuted)
                .tracking(0.8)

            VStack(spacing: 8) {
                historyRow(opponent: "Bob", result: "Won", steps: "12,400 vs 9,800", earned: "+₿ 40", won: true)
                historyRow(opponent: "Emma", result: "Lost", steps: "7,200 vs 8,900", earned: "-₿ 30", won: false)
                historyRow(opponent: "Daniel", result: "Won", steps: "15,100 vs 12,000", earned: "+₿ 60", won: true)
            }
        }
    }

    private func historyRow(opponent: String, result: String, steps: String, earned: String, won: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(won ? SD.success.opacity(0.2) : SD.danger.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: won ? "checkmark" : "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(won ? SD.success : SD.danger)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("vs \(opponent)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ReferenceTheme.textPrimary)
                Text(steps)
                    .font(.system(size: 12))
                    .foregroundColor(ReferenceTheme.textMuted)
            }
            Spacer()
            Text(earned)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(won ? SD.success : SD.danger)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ReferenceTheme.glassCardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(ReferenceTheme.glassBorder, lineWidth: 1)
                )
        )
    }

    // MARK: Create Sheet
    private var createChallengeSheet: some View {
        SheetContainer(title: "New Challenge", isPresented: $showCreateSheet) {
            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(ReferenceTheme.tealStart)
                    Text("Wager virtual Stride currency — no real-world value.")
                        .font(.system(size: 12))
                        .foregroundColor(ReferenceTheme.textMuted)
                }
                .padding(12)
                .background(ReferenceTheme.tealStart.opacity(0.12))
                .cornerRadius(12)

                StrideTextField(placeholder: "Opponent username", text: $opponent)
                StrideTextField(placeholder: "Wager amount (₿)", text: $wager, keyboardType: .numberPad)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Duration")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ReferenceTheme.textMuted)
                    DurationSelector()
                }

                Button {
                    opponent = ""; wager = ""
                    showCreateSheet = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill").font(.system(size: 14, weight: .semibold))
                        Text("Send Challenge").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(ReferenceTheme.tealGradient))
                }
            }
        }
    }
}

// MARK: - Duration Selector
private struct DurationSelector: View {
    @State private var selected = 1
    let options = ["6h", "24h", "3d", "7d"]

    private let tealStart = Color(red: 0.22, green: 0.68, blue: 0.74)
    private let tealEnd = Color(red: 0.12, green: 0.48, blue: 0.55)

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<options.count, id: \.self) { i in
                Button { withAnimation { selected = i } } label: {
                    Text(options[i])
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selected == i ? .white : Color.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selected == i
                            ? AnyView(Capsule().fill(LinearGradient(colors: [tealStart, tealEnd], startPoint: .leading, endPoint: .trailing)))
                            : AnyView(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ChallengesView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengesView()
            .environmentObject(AppStateManager())
            .environmentObject(HealthKitService())
            .preferredColorScheme(.dark)
    }
}

