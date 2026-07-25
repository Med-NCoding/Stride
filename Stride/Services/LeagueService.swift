import Foundation
import Supabase

struct LeagueService {
    private static let userLeaguesKey = "stride_persisted_user_leagues"

    // MARK: - Fetch User Leagues
    static func fetchUserLeagues() async -> [League] {
        // Try fetching from Supabase first
        if let userId = try? await supabase.auth.session.user.id {
            do {
                let rows: [League] = try await supabase
                    .from("leagues")
                    .select()
                    .eq("created_by", value: userId.uuidString.lowercased())
                    .execute()
                    .value
                if !rows.isEmpty {
                    saveLocalLeagues(rows)
                    return rows
                }
            } catch {
                print("[Stride] Supabase fetch leagues failed (falling back to local): \(error.localizedDescription)")
            }
        }
        return getLocalLeagues()
    }

    // MARK: - Create League
    static func createLeague(name: String) async throws -> League {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "LeagueService", code: 400, userInfo: [NSLocalizedDescriptionKey: "League name cannot be empty."])
        }

        let userId = (try? await supabase.auth.session.user.id) ?? UUID()
        let randomCode = "STRIDE-" + String((0..<4).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })

        let newLeague = League(
            id: UUID(),
            name: trimmedName,
            description: "Created by member",
            inviteCode: randomCode,
            createdBy: userId,
            memberCap: 50,
            createdAt: Date()
        )

        // Try inserting into Supabase
        do {
            let saved: League = try await supabase
                .from("leagues")
                .insert(newLeague)
                .select()
                .single()
                .execute()
                .value
            var current = getLocalLeagues()
            current.append(saved)
            saveLocalLeagues(current)
            return saved
        } catch {
            print("[Stride] Supabase league insert error: \(error.localizedDescription)")
            var current = getLocalLeagues()
            current.append(newLeague)
            saveLocalLeagues(current)
            return newLeague
        }
    }

    // MARK: - Join League by Code
    static func joinLeague(code: String) async throws -> League {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanCode.isEmpty else {
            throw NSError(domain: "LeagueService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invite code cannot be empty."])
        }

        // Search local leagues first
        let local = getLocalLeagues()
        if let existing = local.first(where: { $0.inviteCode.uppercased() == cleanCode }) {
            return existing
        }

        // Try searching Supabase
        do {
            let rows: [League] = try await supabase
                .from("leagues")
                .select()
                .eq("invite_code", value: cleanCode)
                .limit(1)
                .execute()
                .value

            if let found = rows.first {
                var current = getLocalLeagues()
                if !current.contains(where: { $0.id == found.id }) {
                    current.append(found)
                    saveLocalLeagues(current)
                }
                return found
            }
        } catch {
            print("[Stride] Supabase join query error: \(error.localizedDescription)")
        }

        // Fallback: create virtual local entry for joined code
        let joinedLeague = League(
            id: UUID(),
            name: "League (\(cleanCode))",
            description: "Joined via invite code",
            inviteCode: cleanCode,
            createdBy: UUID(),
            memberCap: 50,
            createdAt: Date()
        )
        var current = getLocalLeagues()
        current.append(joinedLeague)
        saveLocalLeagues(current)
        return joinedLeague
    }

    // MARK: - Local Storage Helpers
    private static func getLocalLeagues() -> [League] {
        guard let data = UserDefaults.standard.data(forKey: userLeaguesKey),
              let leagues = try? JSONDecoder().decode([League].self, from: data) else {
            return []
        }
        return leagues
    }

    private static func saveLocalLeagues(_ leagues: [League]) {
        if let data = try? JSONEncoder().encode(leagues) {
            UserDefaults.standard.set(data, forKey: userLeaguesKey)
        }
    }
}
