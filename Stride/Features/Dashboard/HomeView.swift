import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var stateManager: AppStateManager
    @State private var stepCount    = 8450
    @State private var stepGoal     = 10000
    @State private var balance      = 420
    @State private var weeklySteps  = 51200
    @State private var leagueRank   = 2

    private var progress: Double { Double(stepCount) / Double(stepGoal) }
    private var progressDeg: Double { progress * 360 }

    var body: some View {
        ZStack(alignment: .top) {
            SD.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: SD.lg) {
                    headerSection
                    stepRingSection
                    statsRow
                    activitySection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, SD.md)
                .padding(.top, 16)
            }
        }
    }

    // MARK: Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Good morning,")
                    .font(.system(size: 14))
                    .foregroundColor(SD.textMuted)
                Text("\(stateManager.currentUser?.displayName ?? stateManager.currentUser?.username ?? "strider") 👋")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(SD.textPrimary)
            }
            Spacer()
            
            // Avatar (Tap to sign out for testing)
            Button {
                Task { await stateManager.signOut() }
            } label: {
                ZStack {
                    Circle()
                        .fill(SD.purpleDim)
                        .frame(width: 46, height: 46)
                    Circle()
                        .strokeBorder(SD.purple.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 46, height: 46)
                    Text(String(stateManager.currentUser?.username.prefix(1) ?? "S").uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(SD.purple)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Step Ring
    private var stepRingSection: some View {
        VStack(spacing: SD.md) {
            ZStack {
                // Glow ring
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(SD.purple.opacity(0.15), lineWidth: 28)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)

                // Track
                Circle()
                    .stroke(SD.bgSurface, lineWidth: 18)
                    .frame(width: 200, height: 200)

                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [SD.purple, SD.purpleLight, SD.purple]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .animation(.easeInOut(duration: 1.0), value: progress)

                // Centre text
                VStack(spacing: 2) {
                    Text("\(stepCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(SD.textPrimary)
                    Text("of \(stepGoal)")
                        .font(.system(size: 13))
                        .foregroundColor(SD.textMuted)
                    Text("steps today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SD.textSecondary)
                }
            }
            .padding(.top, SD.sm)

            // Percentage pill
            Text("\(Int(progress * 100))% of daily goal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(SD.purple)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(SD.purpleDim)
                .cornerRadius(SD.radiusFull)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SD.md)
        .background(RoundedRectangle(cornerRadius: SD.radiusLg).fill(SD.bgCard))
    }

    // MARK: Stats Row
    private var statsRow: some View {
        HStack(spacing: SD.sm) {
            StatCard(
                title: "Stride Balance",
                value: "₿ \(balance)",
                subtitle: "Virtual currency",
                icon: "wallet.pass.fill",
                iconColor: SD.purple,
                accent: true
            )
            StatCard(
                title: "League Rank",
                value: "#\(leagueRank)",
                subtitle: "This week",
                icon: "trophy.fill",
                iconColor: SD.warning
            )
        }
    }

    // MARK: Activity Section
    private var activitySection: some View {
        VStack(spacing: SD.sm) {
            SectionHeader(title: "This Week", action: "See All")

            // Weekly bar chart (simplified)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(zip(["M","T","W","T","F","S","S"],
                                 [6200, 9100, 7400, 10200, 8450, 0, 0])),
                        id: \.0) { day, steps in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(steps > 0 ? (steps >= stepGoal ? SD.purple : SD.purpleDim) : SD.bgSurface)
                            .frame(width: 30, height: max(CGFloat(steps) / 300, 4))
                        Text(day)
                            .font(.system(size: 10))
                            .foregroundColor(SD.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80, alignment: .bottom)
            .padding(SD.md)
            .background(RoundedRectangle(cornerRadius: SD.radiusMd).fill(SD.bgCard))

            // Weekly total strip
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Total")
                        .font(.system(size: 12))
                        .foregroundColor(SD.textMuted)
                    Text("\(weeklySteps.formatted()) steps")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(SD.textPrimary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(SD.success)
                    Text("+12% vs last week")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SD.success)
                }
            }
            .padding(SD.md)
            .background(RoundedRectangle(cornerRadius: SD.radiusMd).fill(SD.bgCard))
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppStateManager())
            .preferredColorScheme(.dark)
    }
}
