import SwiftUI

struct ChallengesView: View {
    @State private var showCreateSheet = false
    @State private var opponent        = ""
    @State private var wager           = ""

    var body: some View {
        ZStack {
            SD.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: SD.lg) {
                    headerSection
                    activeChallengesSection
                    historySection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, SD.md)
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
                    .foregroundColor(SD.textPrimary)
                Text("1-on-1 step battles")
                    .font(.system(size: 14))
                    .foregroundColor(SD.textMuted)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(SD.purple)
                .cornerRadius(SD.radiusFull)
            }
        }
    }

    // MARK: Active Challenges
    private var activeChallengesSection: some View {
        VStack(spacing: SD.sm) {
            SectionHeader(title: "Active", action: "All Challenges")

            VStack(spacing: SD.sm) {
                ChallengeCard(
                    you: "You",
                    opponent: "Alice",
                    yourSteps: 10400,
                    opponentSteps: 8900,
                    wager: 50,
                    hoursLeft: 4
                )
                ChallengeCard(
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

    // MARK: History
    private var historySection: some View {
        VStack(spacing: SD.sm) {
            SectionHeader(title: "Recent Results")

            VStack(spacing: SD.xs) {
                historyRow(opponent: "Bob", result: "Won", steps: "12,400 vs 9,800", earned: "+₿ 40", won: true)
                historyRow(opponent: "Emma", result: "Lost", steps: "7,200 vs 8,900", earned: "-₿ 30", won: false)
                historyRow(opponent: "Daniel", result: "Won", steps: "15,100 vs 12,000", earned: "+₿ 60", won: true)
            }
        }
    }

    private func historyRow(opponent: String, result: String, steps: String, earned: String, won: Bool) -> some View {
        HStack(spacing: SD.sm) {
            ZStack {
                Circle()
                    .fill(won ? SD.success.opacity(0.15) : SD.danger.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: won ? "checkmark" : "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(won ? SD.success : SD.danger)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("vs \(opponent)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SD.textPrimary)
                Text(steps)
                    .font(.system(size: 12))
                    .foregroundColor(SD.textMuted)
            }
            Spacer()
            Text(earned)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(won ? SD.success : SD.danger)
        }
        .padding(SD.sm)
        .background(RoundedRectangle(cornerRadius: SD.radiusMd).fill(SD.bgCard))
    }

    // MARK: Create Sheet
    private var createChallengeSheet: some View {
        SheetContainer(title: "New Challenge", isPresented: $showCreateSheet) {
            VStack(spacing: SD.md) {
                // Info strip
                HStack(spacing: SD.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(SD.purple)
                    Text("Wager virtual Stride currency — no real-world value.")
                        .font(.system(size: 12))
                        .foregroundColor(SD.textMuted)
                }
                .padding(SD.sm)
                .background(SD.purpleDim)
                .cornerRadius(SD.radiusSm)

                StrideTextField(placeholder: "Opponent username", text: $opponent)
                StrideTextField(placeholder: "Wager amount (₿)", text: $wager, keyboardType: .numberPad)

                // Duration quick-select
                VStack(alignment: .leading, spacing: SD.xs) {
                    Text("Duration")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SD.textMuted)
                    DurationSelector()
                }

                PurpleButton("Send Challenge", icon: "bolt.fill") {
                    opponent = ""; wager = ""
                    showCreateSheet = false
                }
            }
        }
    }
}

// MARK: - Duration Selector
private struct DurationSelector: View {
    @State private var selected = 1
    let options = ["6h", "24h", "3d", "7d"]

    var body: some View {
        HStack(spacing: SD.xs) {
            ForEach(0..<options.count, id: \.self) { i in
                Button { withAnimation { selected = i } } label: {
                    Text(options[i])
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selected == i ? .white : SD.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selected == i ? SD.purple : SD.bgSurface)
                        .cornerRadius(SD.radiusSm)
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
