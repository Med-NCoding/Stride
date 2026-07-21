import SwiftUI

struct AuthOnboardingView: View {
    @EnvironmentObject private var stateManager: AppStateManager

    // ── Auth fields ────────────────────────────────────────────────────────
    @State private var email       = ""
    @State private var password    = ""
    @State private var isSignUp    = true   // Toggle between Sign Up and Sign In

    // ── Onboarding fields (shown after account creation) ──────────────────
    @State private var username    = ""
    @State private var displayName = ""
    @State private var internalStep = 0    // 0 = username/displayName, 1 = Health

    // ── Username validation state ──────────────────────────────────────────
    // Drives the inline feedback pill below the username field.
    enum UsernameState {
        case idle           // User hasn't typed yet
        case invalidFormat  // Fails local rules (too short, bad chars…)
        case checking       // Network availability check in flight
        case taken          // Username exists in the DB
        case available      // All good — ready to proceed
    }
    @State private var usernameState: UsernameState = .idle

    // ── Async state ────────────────────────────────────────────────────────
    @State private var isLoading   = false
    @State private var errorMessage: String? = nil
    @State private var profileError: String? = nil  // Error shown on the health card


    var body: some View {
        ZStack {
            SD.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Logo ───────────────────────────────────────────────────
                VStack(spacing: SD.sm) {
                    ZStack {
                        Circle()
                            .fill(SD.purpleDim)
                            .frame(width: 80, height: 80)
                        Circle()
                            .strokeBorder(SD.purple.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 80, height: 80)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(SD.purple)
                    }

                    Text("Stride")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(SD.textPrimary)

                    Text(subtitleText)
                        .font(.system(size: 15))
                        .foregroundColor(SD.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .animation(.easeInOut(duration: SD.animNormal), value: stateManager.rootState)
                }

                Spacer()

                // ── Card ───────────────────────────────────────────────────
                VStack(spacing: SD.md) {
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
                .padding(SD.lg)
                .background(RoundedRectangle(cornerRadius: SD.radiusLg).fill(SD.bgCard))
                .padding(.horizontal, SD.md)
                .padding(.bottom, 40)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Auth Card  (Sign Up / Sign In)
    // ─────────────────────────────────────────────────────────────────────────

    private var authCard: some View {
        VStack(spacing: SD.md) {

            // Mode toggle
            HStack(spacing: 0) {
                modeTab(title: "Sign Up",  active: isSignUp)  { withAnimation { isSignUp = true;  errorMessage = nil } }
                modeTab(title: "Sign In",  active: !isSignUp) { withAnimation { isSignUp = false; errorMessage = nil } }
            }
            .padding(4)
            .background(SD.bgSurface)
            .cornerRadius(SD.radiusSm)

            // Email
            StrideTextField(
                placeholder: "Email address",
                text: $email,
                keyboardType: .emailAddress
            )

            // Password — SecureField so characters are masked
            SecureStrideField(placeholder: "Password", text: $password)

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

            // Primary action button
            PurpleButton(
                isSignUp ? "Create Account" : "Sign In",
                icon: isLoading ? nil : "arrow.right"
            ) {
                Task { await handleAuth() }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    RoundedRectangle(cornerRadius: SD.radiusFull)
                        .fill(SD.purple)
                    ProgressView()
                        .tint(.white)
                }
            }

            // Mode switch hint
            Button {
                withAnimation { isSignUp.toggle(); errorMessage = nil }
            } label: {
                Text(isSignUp
                     ? "Already have an account? Sign in"
                     : "No account yet? Sign up")
                    .font(SFont.caption)
                    .foregroundColor(SD.textMuted)
            }
            .buttonStyle(.plain)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Profile Card  (username + display name)
    // ─────────────────────────────────────────────────────────────────────────

    private var profileCard: some View {
        VStack(spacing: SD.md) {

            // ── Username field ─────────────────────────────────────────────
            VStack(alignment: .leading, spacing: SD.xs) {
                StrideTextField(
                    placeholder: "Username  (e.g. sprint_king)",
                    text: $username
                )
                // Validate format locally on every keystroke
                .onChange(of: username) { _, _ in
                    validateUsernameFormat()
                }

                // Inline feedback pill
                usernameFeedbackPill
            }

            // ── Display name field ─────────────────────────────────────────
            StrideTextField(placeholder: "Display name  (e.g. Medhansh)", text: $displayName)

            Text("Username is your unique handle. Display name is shown to you in the app.")
                .font(SFont.micro)
                .foregroundColor(SD.textMuted)
                .multilineTextAlignment(.center)

            // ── Next button ────────────────────────────────────────────────
            // Enabled only when format is valid; tapping triggers availability check.
            PurpleButton("Next") {
                Task { await handleProfileNext() }
            }
            .disabled(usernameState != .available || isLoading)
            .overlay {
                if usernameState == .checking {
                    RoundedRectangle(cornerRadius: SD.radiusFull)
                        .fill(SD.purple)
                    ProgressView().tint(.white)
                }
            }
        }
    }

    // Inline username status indicator
    @ViewBuilder
    private var usernameFeedbackPill: some View {
        switch usernameState {
        case .idle:
            EmptyView()

        case .invalidFormat:
            // Show the specific format error from the local validator
            if let err = ProfileService.localValidate(username: username) {
                feedbackRow(icon: "xmark.circle.fill", text: err, color: SD.danger)
            }

        case .checking:
            feedbackRow(icon: "arrow.triangle.2.circlepath", text: "Checking availability…", color: SD.textMuted)

        case .taken:
            feedbackRow(icon: "xmark.circle.fill", text: "@\(username.lowercased()) is already taken.", color: SD.danger)

        case .available:
            feedbackRow(icon: "checkmark.circle.fill", text: "@\(username.lowercased()) is available!", color: SD.success)
        }
    }

    private func feedbackRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(SFont.micro)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity)
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Health Card
    // ─────────────────────────────────────────────────────────────────────────

    private var healthCard: some View {
        VStack(spacing: SD.md) {
            HStack(spacing: SD.sm) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(SD.health)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SD.textPrimary)
                    Text("Read-only step count access.")
                        .font(.system(size: 12))
                        .foregroundColor(SD.textMuted)
                }
                Spacer()
            }
            .padding(SD.sm)
            .background(SD.bgSurface)
            .cornerRadius(SD.radiusSm)

            // Error shown here if the Supabase profile insert fails
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

            PurpleButton("Connect & Start Walking") {
                Task { await handleCompleteOnboarding() }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    RoundedRectangle(cornerRadius: SD.radiusFull)
                        .fill(SD.purple)
                    ProgressView().tint(.white)
                }
            }

            Text("Step data is read-only and used solely to calculate virtual Stride currency.")
                .font(.system(size: 11))
                .foregroundColor(SD.textMuted)
                .multilineTextAlignment(.center)
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Helper Views
    // ─────────────────────────────────────────────────────────────────────────

    private func modeTab(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(active ? .white : SD.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    active
                        ? AnyView(RoundedRectangle(cornerRadius: 8).fill(SD.purple))
                        : AnyView(Color.clear)
                )
        }
        .buttonStyle(.plain)
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Username Validation Logic
    // ─────────────────────────────────────────────────────────────────────────

    // Called on every keystroke via .onChange(of: username).
    // Runs the local format check immediately (no network).
    // If format is valid, kicks off the availability check automatically.
    private func validateUsernameFormat() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)

        // If empty go back to idle — don't show errors yet
        guard !trimmed.isEmpty else { usernameState = .idle; return }

        if ProfileService.localValidate(username: trimmed) != nil {
            // Format is bad — show format error instantly
            withAnimation { usernameState = .invalidFormat }
        } else {
            // Format is good — trigger availability check
            Task { await checkUsernameAvailability(trimmed) }
        }
    }

    // Network availability check. Debounced implicitly because it's only called
    // after format validation passes. Marks the field as .checking while in-flight.
    private func checkUsernameAvailability(_ trimmed: String) async {
        withAnimation { usernameState = .checking }
        do {
            let available = try await ProfileService.checkAvailability(username: trimmed)
            withAnimation {
                usernameState = available ? .available : .taken
            }
        } catch {
            // Network error — don't block the user; fall back to idle
            withAnimation { usernameState = .idle }
        }
    }

    // Called when user taps "Next" on the profile card.
    // At this point the username is already .available (button is disabled otherwise),
    // so we just advance the internal step.
    private func handleProfileNext() async {
        guard usernameState == .available else { return }
        withAnimation { internalStep = 1 }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Onboarding Completion Logic
    // ─────────────────────────────────────────────────────────────────────────

    // Called when user taps "Connect & Start Walking" on the health card.
    // Calls AppStateManager.completeOnboarding which inserts into Supabase
    // and transitions rootState → .signedIn.
    private func handleCompleteOnboarding() async {
        isLoading    = true
        profileError = nil
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
        // Guard: both fields must be non-empty
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
            // Map Supabase error messages into user-friendly strings.
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

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Dynamic subtitle
    // ─────────────────────────────────────────────────────────────────────────

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
// MARK: - SecureStrideField
//
// Matches the visual style of StrideTextField but masks input (for passwords).
// Lives here rather than in Shared/ so it doesn't pollute the global component
// namespace until we decide if it's needed elsewhere.
// ─────────────────────────────────────────────────────────────────────────────

struct SecureStrideField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        SecureField(placeholder, text: $text)
            .focused($focused)
            .font(SFont.body)
            .foregroundColor(SD.textPrimary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(SD.sm)
            .background(SD.bgSurface)
            .cornerRadius(SD.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: SD.radiusMd)
                    .strokeBorder(
                        focused ? SD.borderActive : SD.borderDefault,
                        lineWidth: focused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: SD.animFast), value: focused)
    }
}

struct AuthOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        AuthOnboardingView()
            .environmentObject(AppStateManager())
            .preferredColorScheme(.dark)
    }
}
