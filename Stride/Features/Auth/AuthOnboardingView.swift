import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UsernameState
//
// Drives the inline feedback pill shown below the username field.
// Defined at file scope (outside the View struct) so SwiftUI's state
// diffing engine can properly track it as a @State value type.
// ─────────────────────────────────────────────────────────────────────────────
enum UsernameState {
    case idle           // User hasn't typed yet
    case invalidFormat  // Fails local rules (too short, bad chars…)
    case checking       // Network availability check in flight
    case taken          // Username exists in the DB
    case available      // All good — ready to proceed
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Reference Photo Design Palette & Components
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

struct AuthOnboardingView: View {
    @EnvironmentObject private var stateManager:  AppStateManager
    @EnvironmentObject private var healthService: HealthKitService

    // ── Auth fields ────────────────────────────────────────────────────────
    @State private var email       = ""
    @State private var password    = ""
    @State private var isSignUp    = true   // Toggle between Sign Up and Sign In

    // ── Onboarding fields (shown after account creation) ──────────────────
    @State private var username    = ""
    @State private var displayName = ""
    @State private var internalStep = 0    // 0 = username/displayName, 1 = Health

    // ── Username validation state ──────────────────────────────────────────
    @State private var usernameState: UsernameState = .idle

    // ── Async state ────────────────────────────────────────────────────────
    @State private var isLoading   = false
    @State private var errorMessage: String? = nil
    @State private var profileError: String? = nil  // Error shown on the health card

    var body: some View {
        ZStack {
            // Atmospheric gradient background matching reference photo
            LinearGradient(
                colors: [ReferenceTheme.bgTop, ReferenceTheme.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ambient warm glow bokeh (top-right light flare as in reference image)
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
                // ── Top Header Navigation ────────────────────────────────────
                HStack {
                    // Left menu icon
                    Button {
                        // Action if needed
                    } label: {
                        VStack(spacing: 4) {
                            Capsule().fill(Color.white.opacity(0.9)).frame(width: 20, height: 3)
                            Capsule().fill(Color.white.opacity(0.9)).frame(width: 14, height: 3)
                        }
                    }

                    Spacer()

                    // Center Brand
                    Text("Stride")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(ReferenceTheme.textPrimary)

                    Spacer()

                    // Right Icon
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ReferenceTheme.textPrimary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer(minLength: 16)

                // ── Logo & Title Section (matching photo header layout) ──────
                VStack(alignment: .leading, spacing: 6) {
                    Text("stride")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(ReferenceTheme.textPrimary)

                    Text("Welcome")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(ReferenceTheme.textPrimary)

                    Text(subtitleText)
                        .font(.system(size: 14))
                        .foregroundColor(ReferenceTheme.textMuted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.easeInOut(duration: SD.animNormal), value: stateManager.rootState)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.bottom, 16)

                // ── Main Content Glass Card ──────────────────────────────────
                VStack(spacing: 16) {
                    if stateManager.rootState == .signedOut {
                        authCard
                    } else {
                        if internalStep == 0 {
                            profileCard
                        } else {
                            healthCard
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(ReferenceTheme.glassCardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(ReferenceTheme.glassBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 16)

                // ── Bottom Quick Action Tiles (matching bottom 4 tiles in photo) ──
                HStack(spacing: 12) {
                    bottomFeatureTile(icon: "figure.walk", title: "Activity")
                    bottomFeatureTile(icon: "trophy.fill", title: "Leagues")
                    bottomFeatureTile(icon: "bag.fill", title: "Shop")
                    bottomFeatureTile(icon: "person.2.fill", title: "Social")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Auth Card  (Sign Up / Sign In)
    // ─────────────────────────────────────────────────────────────────────────

    private var authCard: some View {
        VStack(spacing: 16) {

            // Mode toggle with Teal active state
            HStack(spacing: 0) {
                modeTab(title: "Sign Up",  active: isSignUp)  { withAnimation { isSignUp = true;  errorMessage = nil } }
                modeTab(title: "Sign In",  active: !isSignUp) { withAnimation { isSignUp = false; errorMessage = nil } }
            }
            .padding(4)
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)

            // Email
            CustomGlassTextField(
                placeholder: "Email address",
                text: $email,
                icon: "envelope.fill",
                keyboardType: .emailAddress
            )

            // Password — Masked SecureField
            CustomGlassSecureField(
                placeholder: "Password",
                text: $password,
                icon: "lock.fill"
            )

            // Inline error — appears below fields if auth fails
            if let error = errorMessage {
                HStack(spacing: SD.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(SD.danger)
                    Text(error)
                        .font(SFont.caption)
                        .foregroundColor(SD.danger)
                }
                .padding(SD.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SD.dangerDim)
                .cornerRadius(SD.radiusSm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Primary action button (Teal Pill Button matching reference CTA)
            TealPillButton(
                title: isSignUp ? "Sign Up" : "Sign In",
                icon: isLoading ? nil : "arrow.right",
                isLoading: isLoading
            ) {
                Task { await handleAuth() }
            }

            // Mode switch hint
            Button {
                withAnimation { isSignUp.toggle(); errorMessage = nil }
            } label: {
                Text(isSignUp
                     ? "Already have an account? Sign in"
                     : "No account yet? Sign up")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ReferenceTheme.textMuted)
            }
            .buttonStyle(.plain)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Profile Card  (username + display name)
    // ─────────────────────────────────────────────────────────────────────────

    private var profileCard: some View {
        VStack(spacing: 16) {

            // ── Username field ─────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                CustomGlassTextField(
                    placeholder: "Username (e.g. sprint_king)",
                    text: $username,
                    icon: "at"
                )
                .onChange(of: username) { _ in
                    validateUsernameFormat()
                }

                // Inline feedback pill
                usernameFeedbackPill
            }

            // ── Display name field ─────────────────────────────────────────
            CustomGlassTextField(
                placeholder: "Display name (e.g. Medhansh)",
                text: $displayName,
                icon: "person.fill"
            )

            Text("Username is your unique handle. Display name is shown to you in the app.")
                .font(.system(size: 12))
                .foregroundColor(ReferenceTheme.textMuted)
                .multilineTextAlignment(.center)

            // ── Next button ────────────────────────────────────────────────
            TealPillButton(
                title: "Next",
                icon: usernameState == .checking ? nil : "arrow.right",
                isLoading: usernameState == .checking || isLoading,
                disabled: usernameState != .available || isLoading
            ) {
                Task { await handleProfileNext() }
            }
        }
    }

    @ViewBuilder
    private var usernameFeedbackPill: some View {
        if usernameState == .invalidFormat,
           let err = ProfileService.localValidate(username: username) {
            feedbackRow(icon: "xmark.circle.fill", text: err, color: SD.danger)
        } else if usernameState == .checking {
            feedbackRow(icon: "arrow.triangle.2.circlepath",
                        text: "Checking availability…",
                        color: ReferenceTheme.textMuted)
        } else if usernameState == .taken {
            feedbackRow(icon: "xmark.circle.fill",
                        text: "@\(username.lowercased()) is already taken.",
                        color: SD.danger)
        } else if usernameState == .available {
            feedbackRow(icon: "checkmark.circle.fill",
                        text: "@\(username.lowercased()) is available!",
                        color: SD.success)
        }
    }

    private func feedbackRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Health Card
    // ─────────────────────────────────────────────────────────────────────────

    private var healthCard: some View {
        VStack(spacing: 16) {

            // ── Header row ────────────────────────────────────────────────────
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ReferenceTheme.tealStart.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ReferenceTheme.tealStart)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ReferenceTheme.textPrimary)
                    Text(healthService.isAvailable
                         ? "Read-only step count access."
                         : "Not available on this device.")
                        .font(.system(size: 12))
                        .foregroundColor(ReferenceTheme.textMuted)
                }
                Spacer()
                // Status badge
                if healthService.status == .authorized {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(SD.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SD.success.opacity(0.12))
                        .cornerRadius(SD.radiusFull)
                } else if healthService.status == .denied {
                    Label("Denied", systemImage: "xmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(SD.danger)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SD.dangerDim)
                        .cornerRadius(SD.radiusFull)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)

            if healthService.status == .denied {
                HStack(spacing: SD.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(SD.info)
                    Text("To enable later: Settings → Privacy → Health → Stride.")
                        .font(.system(size: 11))
                        .foregroundColor(SD.info)
                }
                .padding(SD.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SD.info.opacity(0.10))
                .cornerRadius(SD.radiusSm)
            }

            if let err = profileError {
                HStack(spacing: SD.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(SD.danger)
                    Text(err)
                        .font(SFont.caption)
                        .foregroundColor(SD.danger)
                }
                .padding(SD.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SD.dangerDim)
                .cornerRadius(SD.radiusSm)
                .transition(.opacity)
            }

            TealPillButton(
                title: healthService.status == .authorized
                    ? "Start Walking!"
                    : healthService.status == .denied
                        ? "Continue Without Health"
                        : "Connect & Start Walking",
                isLoading: isLoading,
                disabled: isLoading
            ) {
                Task { await handleCompleteOnboarding() }
            }

            Text("Step data is read-only and never shared with third parties.")
                .font(.system(size: 11))
                .foregroundColor(ReferenceTheme.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Helper Views & Components
    // ─────────────────────────────────────────────────────────────────────────

    private func modeTab(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(active ? .white : ReferenceTheme.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    active
                        ? AnyView(Capsule().fill(ReferenceTheme.tealGradient))
                        : AnyView(Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private func bottomFeatureTile(icon: String, title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ReferenceTheme.textPrimary)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ReferenceTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.20, green: 0.55, blue: 0.62).opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Username Validation Logic
    // ─────────────────────────────────────────────────────────────────────────

    private func validateUsernameFormat() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { usernameState = .idle; return }

        if ProfileService.localValidate(username: trimmed) != nil {
            withAnimation { usernameState = .invalidFormat }
        } else {
            Task { await checkUsernameAvailability(trimmed) }
        }
    }

    private func checkUsernameAvailability(_ trimmed: String) async {
        withAnimation { usernameState = .checking }
        do {
            let available = try await ProfileService.checkAvailability(username: trimmed)
            withAnimation {
                usernameState = available ? .available : .taken
            }
        } catch {
            withAnimation { usernameState = .available }
        }
    }

    private func handleProfileNext() async {
        guard usernameState == .available else { return }
        withAnimation { internalStep = 1 }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Onboarding Completion Logic
    // ─────────────────────────────────────────────────────────────────────────

    private func handleCompleteOnboarding() async {
        isLoading    = true
        profileError = nil

        if healthService.status == .notDetermined && healthService.isAvailable {
            _ = await healthService.requestAuthorization()
            try? await Task.sleep(nanoseconds: 300_000_000)
        }

        do {
            try await stateManager.completeOnboarding(
                username: username,
                displayName: displayName.isEmpty ? nil : displayName
            )
        } catch let profileErr as ProfileError {
            withAnimation { profileError = profileErr.localizedDescription }
        } catch {
            withAnimation { profileError = error.localizedDescription }
        }
        isLoading = false
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Auth Logic
    // ─────────────────────────────────────────────────────────────────────────

    private func handleAuth() async {
        let trimEmail    = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimEmail.isEmpty, !trimPassword.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        guard trimPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isLoading    = true
        errorMessage = nil

        do {
            if isSignUp {
                try await stateManager.signUp(email: trimEmail, password: trimPassword)
            } else {
                try await stateManager.signIn(email: trimEmail, password: trimPassword)
            }
        } catch let authError as AppAuthError {
            errorMessage = authError.localizedDescription
        } catch {
            let msg = error.localizedDescription.lowercased()
            if msg.contains("invalid") || msg.contains("credentials") || msg.contains("wrong") {
                errorMessage = "Incorrect email or password."
            } else if msg.contains("already") || msg.contains("registered") {
                errorMessage = "An account with this email already exists."
            } else if msg.contains("network") || msg.contains("offline") {
                errorMessage = "Check your internet connection and try again."
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    private var subtitleText: String {
        switch stateManager.rootState {
        case .signedOut:
            return isSignUp
                ? "Walk to earn virtual currency.\nCompete with friends."
                : "Welcome back. Sign in to continue."
        case .onboardingRequired:
            return internalStep == 0 ? "Choose your username." : "Connect Apple Health to track your steps."
        default:
            return ""
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Custom UI Helper Controls (Teal & Glassmorphic)
// ─────────────────────────────────────────────────────────────────────────────

struct TealPillButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        disabled
                        ? LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
                        : ReferenceTheme.tealGradient
                    )
            )
            .shadow(color: disabled ? .clear : ReferenceTheme.tealStart.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .disabled(disabled || isLoading)
        .buttonStyle(.plain)
    }
}

struct CustomGlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(isFocused ? ReferenceTheme.tealStart : ReferenceTheme.textMuted)
            }

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .focused($isFocused)
                .font(.system(size: 15))
                .foregroundColor(ReferenceTheme.textPrimary)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isFocused ? ReferenceTheme.tealStart.opacity(0.7) : Color.white.opacity(0.15),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct CustomGlassSecureField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(isFocused ? ReferenceTheme.tealStart : ReferenceTheme.textMuted)
            }

            SecureField(placeholder, text: $text)
                .focused($isFocused)
                .font(.system(size: 15))
                .foregroundColor(ReferenceTheme.textPrimary)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isFocused ? ReferenceTheme.tealStart.opacity(0.7) : Color.white.opacity(0.15),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct AuthOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        AuthOnboardingView()
            .environmentObject(AppStateManager())
            .environmentObject(HealthKitService())
            .preferredColorScheme(.dark)
    }
}

