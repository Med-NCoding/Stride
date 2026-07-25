import Foundation
import Supabase

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ProfileService
//
// Owns all read/write operations against the `profiles` table in Supabase.
// The `profiles` table mirrors the Supabase Auth `auth.users` table via the
// user's UUID primary key, extending it with app-specific fields:
//
//   Column          Type        Notes
//   ──────────────────────────────────────────────────────
//   id              uuid        FK → auth.users.id (PK)
//   username        text        unique, lowercase, 3-20 chars
//   display_name    text?       optional friendly name
//   avatar_url      text?       storage path or CDN URL
//   stride_balance  int4        current virtual currency (default 100)
//   all_time_steps  int8        lifetime verified steps (default 0)
//   created_at      timestamptz auto-set by Postgres
//
// SQL to create the table (run once in the Supabase SQL editor):
// ─────────────────────────────────────────────────────────────────────────────
// create table public.profiles (
//   id            uuid primary key references auth.users on delete cascade,
//   username      text unique not null,
//   display_name  text,
//   avatar_url    text,
//   stride_balance int4 not null default 100,
//   all_time_steps int8 not null default 0,
//   created_at    timestamptz not null default now()
// );
// alter table public.profiles enable row level security;
// create policy "Users can view their own profile"
//   on profiles for select using (auth.uid() = id);
// create policy "Users can insert their own profile"
//   on profiles for insert with check (auth.uid() = id);
// create policy "Users can update their own profile"
//   on profiles for update using (auth.uid() = id);
// ─────────────────────────────────────────────────────────────────────────────

// Codable struct matching the `profiles` table row exactly.
// Used both for INSERT (creating a row) and SELECT (reading it back).
struct ProfileRow: Codable {
    let id: UUID           // Must match auth.users.id
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let strideBalance: Int
    let allTimeSteps: Int
    let createdAt: Date?   // Optional: nil on insert; Postgres fills it in

    // Snake_case ↔ camelCase mapping for Supabase column names.
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName   = "display_name"
        case avatarUrl     = "avatar_url"
        case strideBalance = "stride_balance"
        case allTimeSteps  = "all_time_steps"
        case createdAt     = "created_at"
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom errors thrown by ProfileService so call-sites can display specific UI.
// ─────────────────────────────────────────────────────────────────────────────
enum ProfileError: Error, LocalizedError {
    case usernameTaken
    case notAuthenticated
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .usernameTaken:
            return "That username is already taken. Please choose another."
        case .notAuthenticated:
            return "You must be signed in to create a profile."
        case .saveFailed(let detail):
            return "Could not save profile: \(detail)"
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileService
// ─────────────────────────────────────────────────────────────────────────────
struct ProfileService {

    // MARK: - Username Validation (local, no network)
    //
    // Runs instantly against the typed string before any network call.
    // Returns nil if valid, or a human-readable error string if not.

    static func localValidate(username: String) -> String? {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Username cannot be empty." }
        guard trimmed.count >= 3 else { return "Must be at least 3 characters." }
        guard trimmed.count <= 20 else { return "Must be 20 characters or fewer." }

        // Only lowercase letters, digits, and underscores.
        let allowed = CharacterSet.lowercaseLetters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "_"))
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return "Only lowercase letters, numbers, and underscores."
        }
        // Cannot start or end with underscore.
        guard !trimmed.hasPrefix("_"), !trimmed.hasSuffix("_") else {
            return "Cannot start or end with an underscore."
        }
        return nil // ✓ valid
    }


    // MARK: - Availability Check (network)
    //
    // Queries the `profiles` table for any row with the given username.
    // Returns true if available, false if taken, throws on network error.

    static func checkAvailability(username: String) async throws -> Bool {
        // SELECT count(*) FROM profiles WHERE username = :username LIMIT 1
        // We ask for the id column only — we don't need the full row.
        let rows: [ProfileRow] = try await supabase
            .from("profiles")
            .select("id")
            .eq("username", value: username.lowercased())
            .limit(1)
            .execute()
            .value

        return rows.isEmpty // empty result → username is available
    }


    // MARK: - Create Profile (network, authenticated)
    //
    // Inserts a new row into `profiles` for the currently signed-in user.
    // The user's UUID comes from the active Supabase Auth session.
    // Returns the full saved `ProfileRow` (with server-generated created_at).

    static func createProfile(
        username: String,
        displayName: String?
    ) async throws -> ProfileRow {

        // 1. Get the authenticated user's UUID from the live session.
        guard let userId = try? await supabase.auth.session.user.id else {
            throw ProfileError.notAuthenticated
        }

        // 2. Build the row to insert.
        let row = ProfileRow(
            id: userId,
            username: username.lowercased(),
            displayName: displayName?.isEmpty == false ? displayName : nil,
            avatarUrl: nil,
            strideBalance: 100,   // Starting Stride currency award
            allTimeSteps: 0,
            createdAt: nil        // Postgres fills this in automatically
        )

        // 3. UPSERT INTO profiles VALUES (row)
        // .execute().value decodes the returned row (Postgres RETURNING *).
        do {
            let saved: ProfileRow = try await supabase
                .from("profiles")
                .upsert(row)
                .select()
                .single()
                .execute()
                .value
            return saved
        } catch {
            throw ProfileError.saveFailed(error.localizedDescription)
        }
    }


    // MARK: - Fetch Current Profile (network, authenticated)
    //
    // Reads the profile row for the signed-in user.
    // Returns nil if no profile exists yet (e.g. onboarding not done).

    static func fetchCurrentProfile() async throws -> ProfileRow? {
        guard let userId = try? await supabase.auth.session.user.id else {
            return nil
        }

        let rows: [ProfileRow] = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString.lowercased())
            .limit(1)
            .execute()
            .value

        return rows.first
    }
}
