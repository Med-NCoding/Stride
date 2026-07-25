import Foundation
import SwiftUI
import Combine
@preconcurrency import Supabase

/// Represents the top-level navigation states of the Stride application.
enum AppRootState: String, Codable {
    case loading
    case signedOut
    case onboardingRequired
    case signedIn
}

enum AppAuthError: Error, LocalizedError {
    case emailConfirmationRequired
    
    var errorDescription: String? {
        switch self {
        case .emailConfirmationRequired:
            return "Confirmation email sent! Please check your inbox and verify your email before signing in."
        }
    }
}


@MainActor
final class AppStateManager: ObservableObject {

    @Published var rootState: AppRootState = .loading
    @Published var currentUser: User?      = nil

    // ── UserDefaults Keys ─────────────────────────────────────────────────
    // These store profile data (not session tokens).
    // Session tokens are managed entirely by the Supabase SDK in the iOS Keychain.

    private let isOnboardingCompletedKey = "stride_is_onboarding_completed"
    private let savedUsernameKey         = "stride_saved_username"
    private let savedDisplayNameKey      = "stride_saved_display_name"


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Session Restoration (Cold Launch)
    //
    // Called once from ContentView.onAppear.
    // Asks the Supabase SDK to restore the session it persisted in the Keychain.
    // No network call is made if the token is still valid — it's purely local.
    // ─────────────────────────────────────────────────────────────────────────

    func startInitialLoading() async {
        rootState = .loading

        // Brief boot pause so the splash animation has time to play.
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Ask the SDK if there is a valid stored session.
        // session is non-nil  → user was signed in previously and token has not expired
        // session is nil      → first launch, or user signed out, or token expired
        let session = try? await supabase.auth.session

        if session != nil {
            // Session exists — restore the local User object and go straight to the app.
            await restoreUserFromDefaults()
        } else {
            withAnimation(.easeInOut(duration: SD.animNormal)) {
                rootState = .signedOut
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Sign Up  (new account, email + password)
    // ─────────────────────────────────────────────────────────────────────────

    func signUp(email: String, password: String) async throws {
        // Creates the account in Supabase Auth.
        // The SDK immediately stores the session token in the Keychain on success.
        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )

        // A non-nil session means Supabase did not require email confirmation
        // (auto-confirm is on in Dashboard Settings). Route to onboarding so
        // the user can pick a username.
        if response.session != nil {
            withAnimation(.easeInOut(duration: SD.animNormal)) {
                rootState = .onboardingRequired
            }
        } else {
            // Email confirmation required — throw error to let the UI display instructions.
            throw AppAuthError.emailConfirmationRequired
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Sign In  (existing account, email + password)
    // ─────────────────────────────────────────────────────────────────────────

    func signIn(email: String, password: String) async throws {
        // Exchanges credentials for a session. Stores token in Keychain on success.
        try await supabase.auth.signIn(
            email: email,
            password: password
        )

        // After sign-in, check whether this user already has a profile in Supabase.
        // This is the source of truth — UserDefaults is only a local cache and
        // gets cleared when users sign out or switch devices.
        if let existingProfile = try? await ProfileService.fetchCurrentProfile() {
            // Profile exists → user already completed onboarding, go straight to the app.
            // Cache the data locally for fast future cold-launch restores.
            UserDefaults.standard.set(true,                    forKey: isOnboardingCompletedKey)
            UserDefaults.standard.set(existingProfile.username, forKey: savedUsernameKey)
            if let dn = existingProfile.displayName {
                UserDefaults.standard.set(dn, forKey: savedDisplayNameKey)
            }

            if let session = try? await supabase.auth.session {
                self.currentUser = User(
                    id: session.user.id,
                    username: existingProfile.username,
                    displayName: existingProfile.displayName,
                    avatarUrl: existingProfile.avatarUrl,
                    strideBalance: existingProfile.strideBalance,
                    allTimeSteps: existingProfile.allTimeSteps,
                    onboardingComplete: true,
                    createdAt: existingProfile.createdAt ?? Date()
                )
            }

            withAnimation(.easeInOut(duration: SD.animNormal)) {
                rootState = .signedIn
            }
        } else if let session = try? await supabase.auth.session {
            // User signed in but no profile exists in Supabase.
            // Automatically ensure a profile in Supabase so they are NEVER asked for username/displayName on Sign In.
            let fallbackName = fallbackUsername(for: session.user.email ?? "user", userId: session.user.id)
            let created = try? await ProfileService.createProfile(username: fallbackName, displayName: nil)
            let usernameToUse = created?.username ?? fallbackName
            let displayNameToUse = created?.displayName

            UserDefaults.standard.set(true,           forKey: isOnboardingCompletedKey)
            UserDefaults.standard.set(usernameToUse, forKey: savedUsernameKey)
            if let dn = displayNameToUse {
                UserDefaults.standard.set(dn, forKey: savedDisplayNameKey)
            }

            self.currentUser = User(
                id: session.user.id,
                username: usernameToUse,
                displayName: displayNameToUse,
                avatarUrl: created?.avatarUrl,
                strideBalance: created?.strideBalance ?? 100,
                allTimeSteps: created?.allTimeSteps ?? 0,
                onboardingComplete: true,
                createdAt: created?.createdAt ?? Date()
            )

            withAnimation(.easeInOut(duration: SD.animNormal)) {
                rootState = .signedIn
            }
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Onboarding Completion
    //
    // Called from the Health card after the user picks a username and grants
    // HealthKit permission on SIGN UP. This is the moment we:
    //   1. Write the profile row to Supabase (username, display name, balance…)
    //   2. Cache the profile locally in UserDefaults for fast cold-launch restores
    //   3. Populate currentUser so every view in the app has a User object
    //   4. Transition rootState → .signedIn
    // ─────────────────────────────────────────────────────────────────────────

    func completeOnboarding(username: String, displayName: String?) async throws {
        let finalUsername    = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDisplayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDisplayName = (cleanDisplayName?.isEmpty == false) ? cleanDisplayName : nil

        var resolvedId: UUID = UUID()
        var resolvedBalance: Int = 100
        var resolvedSteps: Int = 0
        var resolvedCreatedAt: Date = Date()

        do {
            let savedProfile = try await ProfileService.createProfile(
                username: finalUsername,
                displayName: finalDisplayName
            )
            resolvedId         = savedProfile.id
            resolvedBalance    = savedProfile.strideBalance
            resolvedSteps      = savedProfile.allTimeSteps
            resolvedCreatedAt  = savedProfile.createdAt ?? Date()
        } catch {
            print("[Stride] Profile save failed (will fallback to local cache): \(error.localizedDescription)")
            if let session = try? await supabase.auth.session {
                resolvedId = session.user.id
            }
        }

        // Cache profile locally so cold launches don't need a DB round-trip.
        UserDefaults.standard.set(true,          forKey: isOnboardingCompletedKey)
        UserDefaults.standard.set(finalUsername, forKey: savedUsernameKey)
        if let dn = finalDisplayName {
            UserDefaults.standard.set(dn, forKey: savedDisplayNameKey)
        }

        // Hydrate in-memory User object.
        self.currentUser = User(
            id: resolvedId,
            username: finalUsername,
            displayName: finalDisplayName,
            avatarUrl: nil,
            strideBalance: resolvedBalance,
            allTimeSteps: resolvedSteps,
            onboardingComplete: true,
            createdAt: resolvedCreatedAt
        )

        withAnimation(.easeInOut(duration: SD.animNormal)) {
            rootState = .signedIn
        }
    }




    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Sign Out
    // ─────────────────────────────────────────────────────────────────────────

    func signOut() async {
        // Revokes the token server-side and wipes it from the Keychain.
        try? await supabase.auth.signOut()

        // Clear the in-memory user and cached profile strings.
        UserDefaults.standard.removeObject(forKey: savedUsernameKey)
        UserDefaults.standard.removeObject(forKey: savedDisplayNameKey)
        self.currentUser = nil

        withAnimation(.easeInOut(duration: SD.animNormal)) {
            rootState = .signedOut
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Helpers
    // ─────────────────────────────────────────────────────────────────────────

    /// Rebuilds the `currentUser` from locally persisted profile data or Supabase,
    /// transitioning the root state to `.signedIn`.
    private func restoreUserFromDefaults() async {
        let onboardingDone   = UserDefaults.standard.bool(forKey: isOnboardingCompletedKey)
        let savedUsername    = UserDefaults.standard.string(forKey: savedUsernameKey) ?? "strider"
        let savedDisplayName = UserDefaults.standard.string(forKey: savedDisplayNameKey)

        if onboardingDone {
            let session = try? await supabase.auth.session
            self.currentUser = User(
                id: session?.user.id ?? UUID(),
                username: savedUsername,
                displayName: savedDisplayName,
                avatarUrl: nil,
                strideBalance: 420,
                allTimeSteps: 51200,
                onboardingComplete: true,
                createdAt: Date()
            )
            withAnimation(.easeInOut(duration: SD.animNormal)) {
                rootState = .signedIn
            }
        } else if let session = try? await supabase.auth.session {
            // Valid session exists on cold launch. Ensure fallback profile and proceed to app.
            let fallbackName = fallbackUsername(for: session.user.email ?? "user", userId: session.user.id)
            let created = try? await ProfileService.createProfile(username: fallbackName, displayName: nil)
            let usernameToUse = created?.username ?? fallbackName

            UserDefaults.standard.set(true,          forKey: isOnboardingCompletedKey)
            UserDefaults.standard.set(usernameToUse, forKey: savedUsernameKey)

            self.currentUser = User(
                id: session.user.id,
                username: usernameToUse,
                displayName: created?.displayName,
                avatarUrl: created?.avatarUrl,
                strideBalance: created?.strideBalance ?? 100,
                allTimeSteps: created?.allTimeSteps ?? 0,
                onboardingComplete: true,
                createdAt: created?.createdAt ?? Date()
            )
            withAnimation(.easeInOut(duration: SD.animNormal)) {
                rootState = .signedIn
            }
        } else {
            withAnimation(.easeInOut(duration: SD.animNormal)) {
                rootState = .signedOut
            }
        }
    }

    /// Derives a clean fallback username from user email address.
    private func fallbackUsername(for email: String, userId: UUID) -> String {
        let prefix = email.components(separatedBy: "@").first?.lowercased() ?? "strider"
        let allowed = CharacterSet.lowercaseLetters.union(.decimalDigits).union(CharacterSet(charactersIn: "_"))
        var clean = String(prefix.unicodeScalars.filter { allowed.contains($0) })
        if clean.count < 3 {
            clean = "strider_\(userId.uuidString.prefix(4).lowercased())"
        } else if clean.count > 20 {
            clean = String(clean.prefix(20))
        }
        return clean
    }
}
