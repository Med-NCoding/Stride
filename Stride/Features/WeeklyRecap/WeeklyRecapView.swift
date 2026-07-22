import SwiftUI

struct WeeklyRecapView: View {
    @State private var totalSteps    = 51200
    @State private var strideEarned  = 51
    @State private var challengesWon = 3
    @State private var challengesLost = 1
    @State private var rankChange    = 2  // improved by 2 spots

    var body: some View {
        ZStack {
            SD.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: SD.lg) {
                    headerSection
                    recapCard
                    breakdownSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, SD.md)
                .padding(.top, 16)
            }
        }
    }

    // MARK: Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Weekly Recap")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(SD.textPrimary)
            Text("Jul 14 – Jul 20")
                .font(.system(size: 14))
                .foregroundColor(SD.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Hero Recap Card
    private var recapCard: some View {
        VStack(spacing: SD.md) {
            // Gradient banner strip
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Great week!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("You walked \(totalSteps.formatted()) steps and climbed \(rankChange) spots in your league.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(SD.md)
            .background(
                LinearGradient(
                    colors: [SD.purple, Color(hex: "#5B21B6")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(SD.radiusMd)

            // 3-stat strip
            HStack(spacing: 1) {
                miniStat(value: "\(totalSteps.formatted())", label: "Steps", icon: "figure.walk", color: SD.purple)
                Divider().background(SD.divider)
                miniStat(value: "₿ \(strideEarned)", label: "Earned", icon: "wallet.pass.fill", color: SD.warning)
                Divider().background(SD.divider)
                miniStat(value: "\(challengesWon)W/\(challengesLost)L", label: "Battles", icon: "bolt.fill", color: SD.success)
            }
            .background(RoundedRectangle(cornerRadius: SD.radiusMd).fill(SD.bgCard))

            // Share button
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Share Recap Card")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(SD.purple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(SD.purpleDim)
                .cornerRadius(SD.radiusSm)
            }
        }
        .padding(SD.md)
        .background(RoundedRectangle(cornerRadius: SD.radiusLg).fill(SD.bgCard))
    }

    private func miniStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(SD.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(SD.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SD.sm)
    }

    // MARK: Breakdown
    private struct DayEntry: Identifiable {
        let id: String
        let day: String
        let steps: Int
    }

    private var breakdownData: [DayEntry] {
        [
            DayEntry(id: "mon", day: "Monday",    steps: 6200),
            DayEntry(id: "tue", day: "Tuesday",   steps: 9100),
            DayEntry(id: "wed", day: "Wednesday", steps: 7400),
            DayEntry(id: "thu", day: "Thursday",  steps: 10200),
            DayEntry(id: "fri", day: "Friday",    steps: 8450),
        ]
    }

    private var breakdownSection: some View {
        VStack(spacing: SD.sm) {
            SectionHeader(title: "Day Breakdown")

            VStack(spacing: 0) {
                ForEach(breakdownData) { entry in
                    HStack {
                        Text(entry.day)
                            .font(.system(size: 14))
                            .foregroundColor(SD.textSecondary)
                        Spacer()
                        // Mini progress
                        RoundedRectangle(cornerRadius: 3)
                            .fill(entry.steps >= 10000 ? SD.purple : SD.purpleDim)
                            .frame(width: CGFloat(entry.steps) / 500, height: 6)
                        Text("\(entry.steps.formatted())")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(entry.steps >= 10000 ? SD.purple : SD.textSecondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.vertical, 11)
                    .padding(.horizontal, SD.sm)

                    if entry.id != "fri" {
                        Divider().background(SD.divider).padding(.horizontal, SD.sm)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: SD.radiusMd).fill(SD.bgCard))
        }
    }
}

struct WeeklyRecapView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyRecapView()
            .environmentObject(AppStateManager())
            .environmentObject(HealthKitService())
            .preferredColorScheme(.dark)
    }
}
