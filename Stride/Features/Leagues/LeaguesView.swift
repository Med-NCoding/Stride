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

struct LeaguesView: View {
    @State private var selectedLeaderboard = 0 // 0 = GOAT steps, 1 = Tycoon wealth
    @State private var showCreateSheet = false
    @State private var showJoinSheet   = false
    @State private var leagueName      = ""
    @State private var inviteCode      = ""

    // Mock data
    let leagues = ["Neighborhood Walkers", "Silicon Valley Runners"]

    let goatData: [(String, Int, Bool)] = [
        ("Alice",    92400, false),
        ("You",      84000, true),
        ("Charlie",  71500, false),
        ("Daniel",   58200, false),
        ("Emma",     49100, false),
    ]

    let tycoonData: [(String, Int, Bool)] = [
        ("Charlie",  840, false),
        ("You",      420, true),
        ("Alice",    380, false),
        ("Emma",     210, false),
        ("Daniel",   95,  false),
    ]

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
                    myLeaguesSection
                    leaderboardSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .sheet(isPresented: $showCreateSheet) { createSheet }
        .sheet(isPresented: $showJoinSheet)   { joinSheet }
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
                Button { showJoinSheet = true } label: {
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
                Button { showCreateSheet = true } label: {
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

            VStack(spacing: 8) {
                ForEach(leagues, id: \.self) { name in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(ReferenceTheme.tealStart.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 15))
                                .foregroundColor(ReferenceTheme.tealStart)
                        }
                        Text(name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(ReferenceTheme.textPrimary)
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

    // MARK: Leaderboard Section
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LEADERBOARD")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ReferenceTheme.textMuted)
                .tracking(0.8)

            // Toggle
            HStack(spacing: 0) {
                leaderboardToggle(title: "GOAT Steps", index: 0)
                leaderboardToggle(title: "Tycoon Wealth", index: 1)
            }
            .padding(4)
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)

            // Rows
            let data = selectedLeaderboard == 0 ? goatData : tycoonData
            VStack(spacing: 0) {
                ForEach(0..<data.count, id: \.self) { i in
                    let entry = data[i]
                    customRankRow(
                        rank: i + 1,
                        name: entry.0,
                        value: selectedLeaderboard == 0
                            ? "\(entry.1.formatted()) steps"
                            : "₿ \(entry.1.formatted())",
                        isCurrentUser: entry.2
                    )
                    if i < data.count - 1 {
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
            // Rank badge
            ZStack {
                Circle()
                    .fill(isCurrentUser ? ReferenceTheme.tealStart.opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: 34, height: 34)
                Text(rank <= 3 ? ["🥇","🥈","🥉"][rank - 1] : "\(rank)")
                    .font(.system(size: rank <= 3 ? 16 : 13, weight: .bold))
                    .foregroundColor(isCurrentUser ? ReferenceTheme.tealStart : ReferenceTheme.textMuted)
            }

            // Avatar
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
                Button {
                    leagueName = ""
                    showCreateSheet = false
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
                Button {
                    inviteCode = ""
                    showJoinSheet = false
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

