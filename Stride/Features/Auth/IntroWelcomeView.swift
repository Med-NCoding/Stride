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
    static let textPrimary = Color.white
    static let textMuted = Color.white.opacity(0.65)
}

struct IntroWelcomeView: View {
    @State private var hasEntered = false

    // Orbiting user avatar icons & initials
    private let avatarIcons = [
        "person.fill", "figure.walk", "flame.fill", "trophy.fill",
        "bolt.fill", "heart.fill", "star.fill", "crown.fill",
        "figure.run", "waveform.path.ecg", "sparkles"
    ]

    var body: some View {
        if hasEntered {
            AuthOnboardingView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
        } else {
            welcomeScreen
                .transition(.opacity)
        }
    }

    private var welcomeScreen: some View {
        ZStack {
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
                .offset(x: 110, y: -120)

            // Secondary cool teal glow
            Circle()
                .fill(ReferenceTheme.tealStart.opacity(0.20))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -120, y: 150)

            VStack(spacing: 0) {
                Spacer()

                // ── Orbiting Contact / Friends Wheel (Matching Reference Photo) ──
                ZStack {
                    // Outer dark orbital track ring
                    Circle()
                        .stroke(Color.black.opacity(0.30), lineWidth: 50)
                        .frame(width: 260, height: 260)

                    // Inner dark orbital track ring
                    Circle()
                        .stroke(Color.black.opacity(0.45), lineWidth: 36)
                        .frame(width: 170, height: 170)

                    // Central white logo card badge
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 84, height: 84)
                        .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 8)
                        .overlay(
                            VStack(spacing: 2) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.20))
                                Text("stride")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.20))
                            }
                        )

                    // Staggered contacts orbiting across inner and outer circular tracks
                    ForEach(0..<11, id: \.self) { index in
                        let isOuter = (index % 2 == 0)
                        let radius: CGFloat = isOuter ? 128 : 86
                        let angle = (Double(index) * (360.0 / 11.0) - 90.0) * .pi / 180.0
                        let x = cos(angle) * radius
                        let y = sin(angle) * radius
                        let size: CGFloat = isOuter ? 40 : 34
                        let isRoundedSquare = (index % 3 == 0)

                        ZStack {
                            Group {
                                if isRoundedSquare {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: index % 2 == 0
                                                ? [ReferenceTheme.tealStart, ReferenceTheme.tealEnd]
                                                : [Color(red: 0.95, green: 0.55, blue: 0.35), Color(red: 0.85, green: 0.40, blue: 0.25)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: index % 2 == 0
                                                ? [Color(red: 0.28, green: 0.38, blue: 0.45), Color(red: 0.16, green: 0.22, blue: 0.28)]
                                                : [ReferenceTheme.tealStart, ReferenceTheme.tealEnd],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                            .frame(width: size, height: size)
                            .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)

                            Image(systemName: avatarIcons[index % avatarIcons.count])
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .offset(x: x, y: y)
                    }
                }
                .padding(.top, 30)

                Spacer()

                // ── Headline & Simple Subtitle Text ─────────────────────────
                VStack(spacing: 12) {
                    Text("Welcome to Stride")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(ReferenceTheme.textPrimary)

                    Text("Join to compete for steps and bet with friends.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(ReferenceTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
                .padding(.bottom, 36)

                // ── "Enter" Pill Button (Matching reference layout) ────────
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasEntered = true
                    }
                } label: {
                    Text("Enter")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

struct IntroWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        IntroWelcomeView()
            .preferredColorScheme(.dark)
    }
}

