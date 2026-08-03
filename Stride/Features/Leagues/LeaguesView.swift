import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Reference Photo Theme Palette & Components
// ─────────────────────────────────────────────────────────────────────────────
private struct ReferenceTheme {
    static let bgTop = Color(red: 0.10, green: 0.12, blue: 0.15)
    static let bgBottom = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let tealStart = Color(red: 0.00, green: 0.72, blue: 0.83)
    static let tealEnd = Color(red: 0.00, green: 0.48, blue: 0.58)
    static let tealGradient = LinearGradient(
        colors: [tealStart, tealEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let glassCardBg = Color.black.opacity(0.45)
    static let glassBorder = Color.white.opacity(0.14)
    static let textPrimary = Color.white
    static let textMuted = Color.white.opacity(0.65)
}

struct LeaguesView: View {
    @EnvironmentObject private var stateManager:  AppStateManager
    @EnvironmentObject private var healthService: HealthKitService

    @State private var selectedLeaderboard = 0 // 0 = Daily steps, 1 = Weekly steps
    @State private var showCreateSheet     = false
    @State private var showJoinSheet       = false
    @State private var leagueName          = ""
    @State private var inviteCode          = ""

    @State private var userLeagues: [League] = []
    @State private var isLoadingLeagues    = false
    @State private var actionError: String? = nil

    var body: some View {
        ZStack {
            // Atmospheric background matching reference photo
            LinearGradient(
                colors: [ReferenceTheme.bgTop, ReferenceTheme.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle warm glow bokeh
            Circle()
                .fill(Color(red: 1.0, green: 0.62, blue: 0.30).opacity(0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: 110, y: -100)

            // Secondary cool teal glow
            Circle()
                .fill(ReferenceTheme.tealStart.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -120, y: 180)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    myLeaguesSection
                    leaderboardSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .task {
            await loadLeagues()
        }
        .sheet(isPresented: $showCreateSheet) { createSheet }
        .sheet(isPresented: $showJoinSheet)   { joinSheet }
    }

    private func loadLeagues() async {
        isLoadingLeagues = true
        userLeagues = await LeagueService.fetchUserLeagues()
        isLoadingLeagues = false
    }

    // MARK: Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Leagues")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ReferenceTheme.textPrimary)
                Text("Compete with friends")
                    .font(.system(size: 14))
                    .foregroundColor(ReferenceTheme.textMuted)
            }
            Spacer()
            HStack(spacing: 12) {
                Button { actionError = nil; showJoinSheet = true } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ReferenceTheme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(ReferenceTheme.glassBorder, lineWidth: 1)
                        )
                }
                Button { actionError = nil; showCreateSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Capsule().fill(ReferenceTheme.tealGradient))
                        .shadow(color: ReferenceTheme.tealStart.opacity(0.4), radius: 6, x: 0, y: 3)
                }
            }
        }
    }

    // MARK: My Leagues
    private var myLeaguesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR LEAGUES")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ReferenceTheme.textMuted)
                .tracking(0.8)

            if userLeagues.isEmpty {
                emptyLeaguesCard
            } else {
                VStack(spacing: 8) {
                    ForEach(userLeagues) { league in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(ReferenceTheme.tealStart.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(ReferenceTheme.tealStart)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(league.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(ReferenceTheme.textPrimary)
                                Text("Code: \(league.inviteCode)")
                                    .font(.system(size: 11))
                                    .foregroundColor(ReferenceTheme.textMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(ReferenceTheme.textMuted)
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
                }
            }
        }
    }

    private var emptyLeaguesCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ReferenceTheme.tealStart.opacity(0.15))
                    .frame(width: 54, height: 54)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 22))
                    .foregroundColor(ReferenceTheme.tealStart)
            }

            VStack(spacing: 4) {
                Text("No Leagues Joined Yet")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ReferenceTheme.textPrimary)
                Text("Create a league or join with an invite code to start competing with friends.")
                    .font(.system(size: 13))
                    .foregroundColor(ReferenceTheme.textMuted)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    actionError = nil
                    showCreateSheet = true
                } label: {
                    Text("Create League")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(ReferenceTheme.tealGradient))
                }

                Button {
                    actionError = nil
                    showJoinSheet = true
                } label: {
                    Text("Join with Code")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ReferenceTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ReferenceTheme.glassCardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(ReferenceTheme.glassBorder, lineWidth: 1)
                )
        )
    }

    // MARK: Leaderboard Section
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LEADERBOARD")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ReferenceTheme.textMuted)
                .tracking(0.8)

            // Toggle
            HStack(spacing: 0) {
                leaderboardToggle(title: "Daily", index: 0)
                leaderboardToggle(title: "Weekly", index: 1)
            }
            .padding(4)
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)

            VStack(spacing: 0) {
                if userLeagues.isEmpty {
                    VStack(spacing: 8) {
                        Text("No League Activity")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ReferenceTheme.textPrimary)
                        Text("Join or create a league to view live leaderboard rankings.")
                            .font(.system(size: 12))
                            .foregroundColor(ReferenceTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                } else {
                    let userName = stateManager.currentUser?.displayName ?? stateManager.currentUser?.username ?? "You"
                    let userSteps = selectedLeaderboard == 0 ? healthService.todaySteps : healthService.weeklySteps

                    customRankRow(
                        rank: 1,
                        name: "\(userName) (You)",
                        value: "\(userSteps.formatted()) steps",
                        isCurrentUser: true
                    )
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

    private func leaderboardToggle(title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedLeaderboard = index }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selectedLeaderboard == index ? .white : ReferenceTheme.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    selectedLeaderboard == index
                        ? AnyView(Capsule().fill(ReferenceTheme.tealGradient))
                        : AnyView(Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private func customRankRow(rank: Int, name: String, value: String, isCurrentUser: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCurrentUser ? ReferenceTheme.tealStart.opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: 34, height: 34)
                Text(rank <= 3 ? ["🥇","🥈","🥉"][rank - 1] : "\(rank)")
                    .font(.system(size: rank <= 3 ? 16 : 13, weight: .bold))
                    .foregroundColor(isCurrentUser ? ReferenceTheme.tealStart : ReferenceTheme.textMuted)
            }

            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 34, height: 34)
                .overlay(
                    Text(name.prefix(1).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isCurrentUser ? ReferenceTheme.tealStart : ReferenceTheme.textPrimary)
                )

            Text(name)
                .font(.system(size: 15, weight: isCurrentUser ? .bold : .regular))
                .foregroundColor(isCurrentUser ? ReferenceTheme.textPrimary : ReferenceTheme.textMuted)
                .lineLimit(1)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isCurrentUser ? ReferenceTheme.tealStart : ReferenceTheme.textPrimary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            Group {
                if isCurrentUser {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ReferenceTheme.tealStart.opacity(0.18))
                }
            }
        )
    }

    // MARK: Sheets
    private var createSheet: some View {
        SheetContainer(title: "Create League", isPresented: $showCreateSheet) {
            VStack(spacing: 16) {
                StrideTextField(placeholder: "League name", text: $leagueName)

                if let err = actionError {
                    Text(err).font(.system(size: 12)).foregroundColor(SD.danger)
                }

                Button {
                    Task {
                        do {
                            _ = try await LeagueService.createLeague(name: leagueName)
                            userLeagues = await LeagueService.fetchUserLeagues()
                            leagueName = ""
                            showCreateSheet = false
                        } catch {
                            actionError = error.localizedDescription
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
                        Text("Create League").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(ReferenceTheme.tealGradient))
                }
            }
        }
    }

    private var joinSheet: some View {
        SheetContainer(title: "Join with Code", isPresented: $showJoinSheet) {
            VStack(spacing: 16) {
                StrideTextField(placeholder: "Invite code", text: $inviteCode)

                if let err = actionError {
                    Text(err).font(.system(size: 12)).foregroundColor(SD.danger)
                }

                Button {
                    Task {
                        do {
                            _ = try await LeagueService.joinLeague(code: inviteCode)
                            userLeagues = await LeagueService.fetchUserLeagues()
                            inviteCode = ""
                            showJoinSheet = false
                        } catch {
                            actionError = error.localizedDescription
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold))
                        Text("Join League").font(.system(size: 15, weight: .semibold))
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

struct LeaguesView_Previews: PreviewProvider {
    static var previews: some View {
        LeaguesView()
            .environmentObject(AppStateManager())
            .environmentObject(HealthKitService())
            .preferredColorScheme(.dark)
    }
}

