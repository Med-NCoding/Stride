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

struct HomeView: View {
    @EnvironmentObject private var stateManager: AppStateManager
    @EnvironmentObject private var healthService: HealthKitService

    @State private var stepGoal     = 10000
    @State private var balance      = 420
    @State private var leagueRank   = 2

    // Real step count fetched from Apple Health
    private var stepCount: Int {
        healthService.todaySteps
    }

    private var weeklySteps: Int {
        healthService.weeklySteps
    }

    private var progress: Double { Double(stepCount) / Double(stepGoal) }

    var body: some View {
        ZStack(alignment: .top) {
            // Atmospheric background matching reference photo
            LinearGradient(
                colors: [ReferenceTheme.bgTop, ReferenceTheme.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ambient warm glow bokeh (top-right light flare)
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
                    stepRingSection
                    statsRow
                    activitySection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .onAppear {
            healthService.refreshAuthStatus()
        }
        .task {
            await healthService.fetchAllSteps()
        }
    }

    // MARK: Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Good morning,")
                    .font(.system(size: 14))
                    .foregroundColor(ReferenceTheme.textMuted)
                Text("\(stateManager.currentUser?.displayName ?? stateManager.currentUser?.username ?? "strider") 👋")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ReferenceTheme.textPrimary)
            }
            Spacer()
            
            // Avatar (Tap to sign out)
            Button {
                Task { await stateManager.signOut() }
            } label: {
                ZStack {
                    Circle()
                        .fill(ReferenceTheme.tealStart.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Circle()
                        .strokeBorder(ReferenceTheme.tealStart.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 48, height: 48)
                    Text(String(stateManager.currentUser?.username.prefix(1) ?? "S").uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ReferenceTheme.tealStart)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Step Ring Section
    private var stepRingSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer subtle glow ring
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(ReferenceTheme.tealStart.opacity(0.15), lineWidth: 28)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)

                // Track
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 18)
                    .frame(width: 200, height: 200)

                // Teal Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [ReferenceTheme.tealStart, ReferenceTheme.tealEnd, ReferenceTheme.tealStart]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .animation(.easeInOut(duration: 1.0), value: progress)

                // Centre text showing real dynamic steps from Apple Health
                VStack(spacing: 2) {
                    Text("\(stepCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(ReferenceTheme.textPrimary)
                    Text("of \(stepGoal)")
                        .font(.system(size: 13))
                        .foregroundColor(ReferenceTheme.textMuted)
                    Text("steps today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ReferenceTheme.textMuted)
                }
            }
            .padding(.top, 8)

            // Percentage pill in Teal Gradient
            Text("\(Int(progress * 100))% of daily goal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(ReferenceTheme.tealGradient))
                .shadow(color: ReferenceTheme.tealStart.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(ReferenceTheme.glassCardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(ReferenceTheme.glassBorder, lineWidth: 1)
                )
        )
    }

    // MARK: Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            glassStatCard(
                title: "Stride Balance",
                value: "₿ \(balance)",
                subtitle: "Virtual currency",
                icon: "wallet.pass.fill",
                iconColor: ReferenceTheme.tealStart
            )
            glassStatCard(
                title: "League Rank",
                value: "#\(leagueRank)",
                subtitle: "This week",
                icon: "trophy.fill",
                iconColor: Color(red: 1.0, green: 0.65, blue: 0.3)
            )
        }
    }

    private func glassStatCard(title: String, value: String, subtitle: String, icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                Spacer()
            }
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(ReferenceTheme.textMuted)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(ReferenceTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(ReferenceTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: Activity Section
    private var activitySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ReferenceTheme.textPrimary)
                Spacer()
                Text("See All")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ReferenceTheme.tealStart)
            }

            // Weekly bar chart
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(zip(["M","T","W","T","F","S","S"],
                                 [6200, 9100, 7400, 10200, stepCount, 0, 0])),
                        id: \.0) { day, steps in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(steps > 0
                                  ? (steps >= stepGoal
                                     ? AnyShapeStyle(ReferenceTheme.tealGradient)
                                     : AnyShapeStyle(ReferenceTheme.tealStart.opacity(0.4)))
                                  : AnyShapeStyle(Color.white.opacity(0.08)))
                            .frame(width: 28, height: max(CGFloat(steps) / 300, 6))
                        Text(day)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(ReferenceTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90, alignment: .bottom)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(ReferenceTheme.glassCardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(ReferenceTheme.glassBorder, lineWidth: 1)
                    )
            )

            // Weekly total strip showing live weekly steps from HealthKit
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Total")
                        .font(.system(size: 12))
                        .foregroundColor(ReferenceTheme.textMuted)
                    Text("\(weeklySteps.formatted()) steps")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(ReferenceTheme.textPrimary)
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
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppStateManager())
            .environmentObject(HealthKitService())
            .preferredColorScheme(.dark)
    }
}


