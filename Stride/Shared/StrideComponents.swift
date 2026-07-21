import SwiftUI

// MARK: - Custom Floating Tab Bar

enum StrideTab: Int, CaseIterable {
    case home, leagues, challenges, recap

    var label: String {
        switch self {
        case .home:       return "Home"
        case .leagues:    return "Leagues"
        case .challenges: return "Challenges"
        case .recap:      return "Recap"
        }
    }

    var icon: String {
        switch self {
        case .home:       return "figure.walk"
        case .leagues:    return "person.3.fill"
        case .challenges: return "bolt.fill"
        case .recap:      return "chart.bar.fill"
        }
    }
}

struct StrideTabBar: View {
    @Binding var selected: StrideTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StrideTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: selected == tab ? 20 : 18, weight: .semibold))
                            .foregroundColor(selected == tab ? SD.purple : SD.textMuted)
                            .scaleEffect(selected == tab ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)

                        Text(tab.label)
                            .font(.system(size: 10, weight: selected == tab ? .semibold : .regular))
                            .foregroundColor(selected == tab ? SD.purple : SD.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if selected == tab {
                                RoundedRectangle(cornerRadius: SD.radiusSm)
                                    .fill(SD.purpleDim)
                                    .padding(.horizontal, 6)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, SD.sm)
        .padding(.bottom, 8)
        .padding(.top, 6)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(SD.bgCard)
                .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: SD.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                Spacer()
                if accent {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(SD.textMuted)
                }
            }

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(SD.textPrimary)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SD.textSecondary)

            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundColor(SD.textMuted)
            }
        }
        .padding(SD.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: SD.radiusMd).fill(SD.bgCard))
    }
}

// MARK: - Rank Row
struct RankRow: View {
    let rank: Int
    let name: String
    let value: String
    let isCurrentUser: Bool

    var rankColor: Color {
        switch rank {
        case 1: return SD.warning
        case 2: return SD.textSecondary
        case 3: return Color(hex: "#CD7F32")
        default: return SD.textMuted
        }
    }

    var body: some View {
        HStack(spacing: SD.sm) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(isCurrentUser ? SD.purpleDim : rankColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Text(rank <= 3 ? ["🥇","🥈","🥉"][rank - 1] : "\(rank)")
                    .font(.system(size: rank <= 3 ? 16 : 13, weight: .bold))
                    .foregroundColor(isCurrentUser ? SD.purple : rankColor)
            }

            // Avatar
            Circle()
                .fill(SD.bgSurface)
                .frame(width: 34, height: 34)
                .overlay(
                    Text(name.prefix(1).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isCurrentUser ? SD.purple : SD.textSecondary)
                )

            Text(name)
                .font(.system(size: 15, weight: isCurrentUser ? .semibold : .regular))
                .foregroundColor(isCurrentUser ? SD.textPrimary : SD.textSecondary)
                .lineLimit(1)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isCurrentUser ? SD.purple : SD.textSecondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, SD.sm)
        .background(
            Group {
                if isCurrentUser {
                    RoundedRectangle(cornerRadius: SD.radiusSm)
                        .fill(SD.purpleDim)
                }
            }
        )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(SD.textMuted)
                .textCase(.uppercase)
                .tracking(0.8)
            Spacer()
            if let action {
                Button { onAction?() } label: {
                    Text(action)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SD.purple)
                }
            }
        }
    }
}

// MARK: - Challenge Card
struct ChallengeCard: View {
    let you: String
    let opponent: String
    let yourSteps: Int
    let opponentSteps: Int
    let wager: Int
    let hoursLeft: Int

    var total: Double { Double(yourSteps + opponentSteps) }
    var yourRatio: Double { total > 0 ? Double(yourSteps) / total : 0.5 }
    var isWinning: Bool { yourSteps >= opponentSteps }

    var body: some View {
        VStack(alignment: .leading, spacing: SD.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(you) vs \(opponent)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(SD.textPrimary)
                    HStack(spacing: SD.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("\(hoursLeft)h left")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(SD.textMuted)
                }
                Spacer()
                // Wager badge
                HStack(spacing: 4) {
                    Text("₿ \(wager)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(SD.purple)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(SD.purpleDim)
                .cornerRadius(SD.radiusFull)
            }

            // Progress bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(SD.bgSurface)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [SD.purple, SD.purpleLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(yourRatio), height: 8)
                            .animation(.easeInOut(duration: 0.6), value: yourRatio)
                    }
                }
                .frame(height: 8)

                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(SD.purple).frame(width: 7, height: 7)
                        Text("\(stepString(yourSteps))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(SD.textPrimary)
                        Text("you")
                            .font(.system(size: 11))
                            .foregroundColor(SD.textMuted)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text(opponent)
                            .font(.system(size: 11))
                            .foregroundColor(SD.textMuted)
                        Text("\(stepString(opponentSteps))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(SD.textSecondary)
                        Circle().fill(SD.bgSurface).frame(width: 7, height: 7)
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
        .padding(SD.md)
        .background(RoundedRectangle(cornerRadius: SD.radiusMd).fill(SD.bgCard))
    }

    func stepString(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n)/1000) : "\(n)"
    }
}

// MARK: - Sheet Container
struct SheetContainer<Content: View>: View {
    let title: String
    @Binding var isPresented: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            SD.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(SD.bgSurface)
                    .frame(width: 36, height: 4)
                    .padding(.top, SD.md)
                    .padding(.bottom, SD.sm)

                // Title row
                HStack {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(SD.textPrimary)
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(SD.textMuted)
                            .frame(width: 30, height: 30)
                            .background(SD.bgCard)
                            .cornerRadius(SD.radiusFull)
                    }
                }
                .padding(.horizontal, SD.md)
                .padding(.bottom, SD.md)

                Divider().background(SD.divider)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: SD.md) {
                        content()
                    }
                    .padding(SD.md)
                }
            }
        }
    }
}

// MARK: - Stride Text Field
struct StrideTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(SD.textMuted))
            .font(.system(size: 15))
            .foregroundColor(SD.textPrimary)
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .padding(SD.sm)
            .background(SD.bgSurface)
            .cornerRadius(SD.radiusSm)
            .overlay(
                RoundedRectangle(cornerRadius: SD.radiusSm)
                    .strokeBorder(text.isEmpty ? Color.clear : SD.purple.opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - Purple Primary Button
struct PurpleButton: View {
    let label: String
    let icon: String?
    let action: () -> Void

    init(_ label: String, icon: String? = nil, action: @escaping () -> Void) {
        self.label = label; self.icon = icon; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 14, weight: .semibold)) }
                Text(label).font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [SD.purple, SD.purpleLight], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(SD.radiusSm)
        }
    }
}
