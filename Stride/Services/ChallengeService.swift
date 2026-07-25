import Foundation
import Supabase

struct ChallengeService {
    private static let activeChallengesKey = "stride_persisted_active_challenges"

    // MARK: - Fetch Active Challenges
    static func fetchActiveChallenges() async -> [Challenge] {
        if let userId = try? await supabase.auth.session.user.id {
            do {
                let rows: [Challenge] = try await supabase
                    .from("challenges")
                    .select()
                    .or("challenger_id.eq.\(userId.uuidString.lowercased()),opponent_id.eq.\(userId.uuidString.lowercased())")
                    .eq("status", value: "active")
                    .execute()
                    .value
                if !rows.isEmpty {
                    saveLocalChallenges(rows)
                    return rows
                }
            } catch {
                print("[Stride] Supabase fetch challenges failed: \(error.localizedDescription)")
            }
        }
        return getLocalChallenges()
    }

    // MARK: - Create Challenge
    static func createChallenge(opponentUsername: String, wager: Int, durationHours: Int) async throws -> Challenge {
        let cleanOpponent = opponentUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanOpponent.isEmpty else {
            throw NSError(domain: "ChallengeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Opponent username cannot be empty."])
        }
        guard wager >= 0 else {
            throw NSError(domain: "ChallengeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Wager must be 0 or greater."])
        }

        let userId = (try? await supabase.auth.session.user.id) ?? UUID()
        let now = Date()

        let newChallenge = Challenge(
            id: UUID(),
            challengerId: userId,
            opponentId: UUID(), // Placeholder opponent ID until resolved by handle
            leagueId: nil,
            type: .headToHead,
            stepGoal: nil,
            durationHours: durationHours,
            challengerWager: wager,
            opponentWager: wager,
            challengerSteps: 0,
            opponentSteps: 0,
            status: .active,
            winnerId: nil,
            challengerFinalSteps: nil,
            opponentFinalSteps: nil,
            createdAt: now,
            startedAt: now,
            endsAt: Calendar.current.date(byAdding: .hour, value: durationHours, to: now)
        )

        // Try inserting into Supabase
        do {
            let saved: Challenge = try await supabase
                .from("challenges")
                .insert(newChallenge)
                .select()
                .single()
                .execute()
                .value
            var current = getLocalChallenges()
            current.append(saved)
            saveLocalChallenges(current)
            return saved
        } catch {
            print("[Stride] Supabase create challenge error: \(error.localizedDescription)")
            var current = getLocalChallenges()
            current.append(newChallenge)
            saveLocalChallenges(current)
            return newChallenge
        }
    }

    // MARK: - Local Storage Helpers
    private static func getLocalChallenges() -> [Challenge] {
        guard let data = UserDefaults.standard.data(forKey: activeChallengesKey),
              let challenges = try? JSONDecoder().decode([Challenge].self, from: data) else {
            return []
        }
        return challenges
    }

    private static func saveLocalChallenges(_ challenges: [Challenge]) {
        if let data = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(data, forKey: activeChallengesKey)
        }
    }
}
