import SwiftUI

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
            SD.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: SD.lg) {
                    headerSection
                    myLeaguesSection
                    leaderboardSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, SD.md)
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
                    .foregroundColor(SD.textPrimary)
                Text("Compete with friends")
                    .font(.system(size: 14))
                    .foregroundColor(SD.textMuted)
            }
            Spacer()
            HStack(spacing: SD.sm) {
                Button { showJoinSheet = true } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SD.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(SD.bgCard)
                        .cornerRadius(SD.radiusSm)
                }
                Button { showCreateSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(SD.purple)
                        .cornerRadius(SD.radiusSm)
                }
            }
        }
    }

    // MARK: My Leagues
    private var myLeaguesSection: some View {
        VStack(spacing: SD.sm) {
            SectionHeader(title: "Your Leagues")

            VStack(spacing: SD.xs) {
                ForEach(leagues, id: \.self) { name in
                    HStack(spacing: SD.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(SD.purpleDim)
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 15))
                                .foregroundColor(SD.purple)
                        }
                        Text(name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(SD.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(SD.textMuted)
                    }
                    .padding(SD.sm)
                    .background(RoundedRectangle(cornerRadius: SD.radiusMd).fill(SD.bgCard))
                }
            }
        }
    }

    // MARK: Leaderboard Section
    private var leaderboardSection: some View {
        VStack(spacing: SD.sm) {
            SectionHeader(title: "Leaderboard")

            // Toggle
            HStack(spacing: 0) {
                leaderboardToggle(title: "GOAT Steps", index: 0)
                leaderboardToggle(title: "Tycoon Wealth", index: 1)
            }
            .padding(4)
            .background(SD.bgCard)
            .cornerRadius(SD.radiusSm)

            // Rows
            let data = selectedLeaderboard == 0 ? goatData : tycoonData
            VStack(spacing: 0) {
                ForEach(0..<data.count, id: \.self) { i in
                    let entry = data[i]
                    RankRow(
                        rank: i + 1,
                        name: entry.0,
                        value: selectedLeaderboard == 0
                            ? "\(entry.1.formatted()) steps"
                            : "₿ \(entry.1.formatted())",
                        isCurrentUser: entry.2
                    )
                    if i < data.count - 1 {
                        Divider().background(SD.divider).padding(.horizontal, SD.sm)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: SD.radiusMd).fill(SD.bgCard))
        }
    }

    private func leaderboardToggle(title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedLeaderboard = index }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selectedLeaderboard == index ? .white : SD.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    selectedLeaderboard == index
                        ? AnyView(RoundedRectangle(cornerRadius: 8).fill(SD.purple))
                        : AnyView(Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Sheets
    private var createSheet: some View {
        SheetContainer(title: "Create League", isPresented: $showCreateSheet) {
            VStack(spacing: SD.md) {
                StrideTextField(placeholder: "League name", text: $leagueName)
                PurpleButton("Create League", icon: "plus") {
                    leagueName = ""
                    showCreateSheet = false
                }
            }
        }
    }

    private var joinSheet: some View {
        SheetContainer(title: "Join with Code", isPresented: $showJoinSheet) {
            VStack(spacing: SD.md) {
                StrideTextField(placeholder: "Invite code", text: $inviteCode)
                PurpleButton("Join League", icon: "arrow.right") {
                    inviteCode = ""
                    showJoinSheet = false
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
