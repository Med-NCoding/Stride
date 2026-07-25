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

struct WeeklyRecapView: View {
    @State private var totalSteps    = 51200
    @State private var strideEarned  = 51
    @State private var challengesWon = 3
    @State private var challengesLost = 1
    @State private var rankChange    = 2  // improved by 2 spots

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
                    recapCard
                    breakdownSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
    }

    // MARK: Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Weekly Recap")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ReferenceTheme.textPrimary)
            Text("Jul 14 – Jul 20")
                .font(.system(size: 14))
                .foregroundColor(ReferenceTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Hero Recap Card
    private var recapCard: some View {
        VStack(spacing: 16) {
            // Teal Gradient banner strip
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Great week!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("You walked \(totalSteps.formatted()) steps and climbed \(rankChange) spots in your league.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(3)
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                Capsule()
                    .fill(ReferenceTheme.tealGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            )
            .shadow(color: ReferenceTheme.tealStart.opacity(0.3), radius: 8, x: 0, y: 4)

            // 3-stat strip
            HStack(spacing: 1) {
                miniStat(value: "\(totalSteps.formatted())", label: "Steps", icon: "figure.walk", color: ReferenceTheme.tealStart)
                Divider().background(Color.white.opacity(0.12))
                miniStat(value: "₿ \(strideEarned)", label: "Earned", icon: "wallet.pass.fill", color: Color(red: 1.0, green: 0.65, blue: 0.3))
                Divider().background(Color.white.opacity(0.12))
                miniStat(value: "\(challengesWon)W/\(challengesLost)L", label: "Battles", icon: "bolt.fill", color: SD.success)
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )

            // Share button
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Share Recap Card")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Capsule().fill(ReferenceTheme.tealGradient))
                .shadow(color: ReferenceTheme.tealStart.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(ReferenceTheme.glassCardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(ReferenceTheme.glassBorder, lineWidth: 1)
                )
        )
    }

    private func miniStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(ReferenceTheme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(ReferenceTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("DAY BREAKDOWN")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ReferenceTheme.textMuted)
                .tracking(0.8)

            VStack(spacing: 0) {
                ForEach(breakdownData) { entry in
                    HStack {
                        Text(entry.day)
                            .font(.system(size: 14))
                            .foregroundColor(ReferenceTheme.textMuted)
                        Spacer()
                        // Mini progress
                        RoundedRectangle(cornerRadius: 3)
                            .fill(entry.steps >= 10000 ? AnyShapeStyle(ReferenceTheme.tealGradient) : AnyShapeStyle(ReferenceTheme.tealStart.opacity(0.4)))
                            .frame(width: CGFloat(entry.steps) / 500, height: 6)
                        Text("\(entry.steps.formatted())")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(entry.steps >= 10000 ? ReferenceTheme.tealStart : ReferenceTheme.textMuted)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)

                    if entry.id != "fri" {
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal, 12)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(ReferenceTheme.glassCardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(ReferenceTheme.glassBorder, lineWidth: 1)
                    )
            )
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

