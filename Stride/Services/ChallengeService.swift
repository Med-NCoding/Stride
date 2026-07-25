import Foundation
import Supabase

struct ChallengeService {
    private static let persistedChallengesKey = "stride_persisted_challenges"

    // MARK: - Fetch User Challenges (Invited & Active)
    static func fetchUserChallenges() async -> (pending: [Challenge], active: [Challenge]) {
        if let userId = try? await supabase.auth.session.user.id {
            do {
                let rows: [Challenge] = try await supabase
                    .from("challenges")
                    .select()
                    .or("challenger_id.eq.\(userId.uuidString.lowercased()),opponent_id.eq.\(userId.uuidString.lowercased())")
                    .execute()
                    .value
                
                if !rows.isEmpty {
                    saveLocalChallenges(rows)
                    let pending = rows.filter { $0.status == .invited }
                    let active = rows.filter { $0.status == .active }
                    return (pending, active)
                }
            } catch {
                print("[Stride] Supabase fetch challenges failed: \(error.localizedDescription)")
            }
        }
        
        let allLocal = getLocalChallenges()
        let pending = allLocal.filter { $0.status == .invited }
        let active = allLocal.filter { $0.status == .active }
        return (pending, active)
    }

    // MARK: - Create Wager Request
    static func createChallenge(opponentUsername: String, wager: Int, durationHours: Int) async throws -> Challenge {
        let cleanOpponent = opponentUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanOpponent.isEmpty else {
            throw NSError(domain: "ChallengeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Opponent username cannot be empty."])
        }
        guard wager >= 0 else {
            throw NSError(domain: "ChallengeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Wager must be 0 or greater."])
        }

        let userId = (try? await supabase.auth.session.user.id) ?? UUID()

        // 1. Verify that opponent exists in Supabase profiles
        let targetOpponentId: UUID
        do {
            let matchingProfiles: [ProfileRow] = try await supabase
                .from("profiles")
                .select("id, username, display_name")
                .eq("username", value: cleanOpponent)
                .limit(1)
                .execute()
                .value
            
            guard let profile = matchingProfiles.first else {
                throw NSError(
                    domain: "ChallengeService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "User '@\(cleanOpponent)' does not exist. Please check the username and try again."]
                )
            }
            
            if profile.id == userId {
                throw NSError(
                    domain: "ChallengeService",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "You cannot send a wager challenge to yourself."]
                )
            }
            
            targetOpponentId = profile.id
        } catch let err as NSError where err.domain == "ChallengeService" {
            throw err
        } catch {
            print("[Stride] Profile verification warning: \(error.localizedDescription)")
            // Fallback for offline testing if user isn't found via network error
            targetOpponentId = UUID()
        }

        let now = Date()
        let newChallenge = Challenge(
            id: UUID(),
            challengerId: userId,
            opponentId: targetOpponentId,
            leagueId: nil,
            type: .headToHead,
            stepGoal: nil,
            durationHours: durationHours,
            challengerWager: wager,
            opponentWager: wager,
            challengerSteps: 0,
            opponentSteps: 0,
            status: .invited, // Request state: user doesn't join until accepted!
            winnerId: nil,
            challengerFinalSteps: nil,
            opponentFinalSteps: nil,
            createdAt: now,
            startedAt: nil,
            endsAt: nil
        )

        // 2. Insert wager request into Supabase
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

    // MARK: - Accept Wager Request
    static func acceptChallenge(id: UUID) async throws {
        let now = Date()
        let local = getLocalChallenges()
        guard let match = local.first(where: { $0.id == id }) else { return }
        
        let duration = match.durationHours
        let endsAt = Calendar.current.date(byAdding: .hour, value: duration, to: now)

        struct AcceptPayload: Encodable {
            let status: String
            let started_at: Date
            let ends_at: Date?
        }

        let payload = AcceptPayload(status: "active", started_at: now, ends_at: endsAt)

        do {
            try await supabase
                .from("challenges")
                .update(payload)
                .eq("id", value: id.uuidString.lowercased())
                .execute()
        } catch {
            print("[Stride] Supabase accept challenge failed: \(error.localizedDescription)")
        }

        var updatedList = local
        if let idx = updatedList.firstIndex(where: { $0.id == id }) {
            updatedList[idx].status = .active
            saveLocalChallenges(updatedList)
        }
    }

    // MARK: - Decline / Cancel Wager Request
    static func declineChallenge(id: UUID) async throws {
        struct DeclinePayload: Encodable {
            let status: String
        }

        let payload = DeclinePayload(status: "cancelled")

        do {
            try await supabase
                .from("challenges")
                .update(payload)
                .eq("id", value: id.uuidString.lowercased())
                .execute()
        } catch {
            print("[Stride] Supabase decline challenge failed: \(error.localizedDescription)")
        }

        var updatedList = getLocalChallenges()
        if let idx = updatedList.firstIndex(where: { $0.id == id }) {
            updatedList[idx].status = .cancelled
            saveLocalChallenges(updatedList)
        }
    }

    // MARK: - Local Storage Helpers
    private static func getLocalChallenges() -> [Challenge] {
        guard let data = UserDefaults.standard.data(forKey: persistedChallengesKey),
              let challenges = try? JSONDecoder().decode([Challenge].self, from: data) else {
            return []
        }
        return challenges
    }

    private static func saveLocalChallenges(_ challenges: [Challenge]) {
        if let data = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(data, forKey: persistedChallengesKey)
        }
    }
}
