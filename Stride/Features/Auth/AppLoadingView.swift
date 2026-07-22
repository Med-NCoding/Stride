import SwiftUI

struct AppLoadingView: View {
    @State private var isAnimating = false
    @State private var isGlowAnimating = false
    @State private var statusText = "Checking local session..."
    
    // An array of status messages to simulate step synchronization
    private let statusMessages = [
        "Checking local session...",
        "Establishing Supabase tunnel...",
        "Syncing step count telemetry...",
        "Calculating Stride balance...",
        "Optimizing dashboard..."
    ]
    
    var body: some View {
        ZStack {
            SD.bgPrimary.ignoresSafeArea()
            
            // Subtle background radial gradient for depth
            RadialGradient(
                colors: [SD.purple.opacity(0.12), Color.clear],
                center: .center,
                startRadius: 5,
                endRadius: 280
            )
            .ignoresSafeArea()
            
            VStack(spacing: SD.lg) {
                Spacer()
                
                // Animated Pulsing Central Logo / Icon
                ZStack {
                    // Outer pulsing glow circle
                    Circle()
                        .fill(SD.purpleGlow)
                        .frame(width: 130, height: 130)
                        .scaleEffect(isGlowAnimating ? 1.25 : 0.95)
                        .opacity(isGlowAnimating ? 0.3 : 0.75)
                    
                    // Middle border pulse
                    Circle()
                        .strokeBorder(SD.purple.opacity(0.4), lineWidth: 2)
                        .frame(width: 110, height: 110)
                        .scaleEffect(isGlowAnimating ? 1.15 : 0.98)
                    
                    // Central dark card background
                    Circle()
                        .fill(SD.bgCard)
                        .frame(width: 90, height: 90)
                        .shadow(color: SD.purple.opacity(0.3), radius: 15)
                    
                    // Active walking symbol
                    Image(systemName: "figure.walk")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(SD.purpleLight)
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                        .offset(y: isAnimating ? -3 : 3)
                }
                
                // Stride Brand Header
                VStack(spacing: SD.xs) {
                    Text("Stride")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(SD.textPrimary)
                        .tracking(1.2)
                    
                    // Simulated status message text
                    Text(statusText)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(SD.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(height: 24)
                        .transition(.opacity)
                }
                .padding(.top, SD.md)
                
                Spacer()
                
                // Indefinite Loading Ring (Micro-animation)
                ZStack {
                    Circle()
                        .stroke(SD.bgSurface, lineWidth: 3.5)
                        .frame(width: 28, height: 28)
                    
                    Circle()
                        .trim(from: 0.0, to: 0.35)
                        .stroke(SD.purple, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Start the infinite micro-animations
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                isGlowAnimating = true
            }
            
            // Cycle through status messages
            startStatusCycle()
        }
    }
    
    private func startStatusCycle() {
        var delay: Double = 0.3
        for message in statusMessages {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    statusText = message
                }
            }
            delay += 0.35
        }
    }
}

#Preview {
    AppLoadingView()
        .environmentObject(AppStateManager())
        .environmentObject(HealthKitService())
}
