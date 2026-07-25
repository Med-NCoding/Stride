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

    // Orbiting user avatar mock data
    private let avatarIcons = [
        "figure.walk", "person.fill", "flame.fill", "trophy.fill",
        "bolt.fill", "heart.fill", "star.fill", "crown.fill",
        "figure.run", "waveform.path.ecg"
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

                // ── Orbiting Contact / Friends Wheel (matching reference image) ──
                ZStack {
                    // Outer dark orbital ring track
                    Circle()
                        .stroke(Color.black.opacity(0.25), lineWidth: 48)
                        .frame(width: 250, height: 250)

                    // Inner dark orbital ring track
                    Circle()
                        .stroke(Color.black.opacity(0.40), lineWidth: 32)
                        .frame(width: 170, height: 170)

                    // Central white logo card badge
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
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

                    // Orbiting small circles around the wheel
                    ForEach(0..<10, id: \.self) { index in
                        let angle = Double(index) * (360.0 / 10.0) * .pi / 180.0
                        let radius: CGFloat = 115
                        let x = cos(angle) * radius
                        let y = sin(angle) * radius

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: index % 2 == 0
                                        ? [ReferenceTheme.tealStart, ReferenceTheme.tealEnd]
                                        : [Color(red: 1.0, green: 0.6, blue: 0.3), Color(red: 0.9, green: 0.4, blue: 0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

                            Image(systemName: avatarIcons[index % avatarIcons.count])
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: x, y: y)
                    }
                }
                .padding(.top, 40)

                Spacer()

                // ── Headline & Simple Non-AI Subtitle Text ─────────────────
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

                // ── "Enter" Pill Button (matching reference layout) ────────
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
