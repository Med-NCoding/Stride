import Foundation
import Combine

// SupabaseService owns all remote data operations.
// Today every method is a stub that returns mock data.
// When Supabase is wired up, replace the stub body with the real SDK call —
// the function signatures and published properties must NOT change so that
// call-sites throughout the app continue to compile without modification.

class SupabaseService: ObservableObject {

    // ── Published State ───────────────────────────────────────────────────
    // Views observe these directly via @EnvironmentObject or @ObservedObject.

    @Published var currentUser: User? = nil

    /// All leagues the signed-in user belongs to (as admin or member).
    @Published var activeLeagues: [League] = []

    /// The membership records for the current user across all their leagues.
    /// One entry per league the user has joined or created.
    @Published var myMemberships: [LeagueMember] = []

    /// Members of whichever league is currently open on screen.
    /// Populated by fetchMembers(forLeague:).
    @Published var activeMembership: [LeagueMember] = []

    /// Step snapshots for the current week, for the open league.
    @Published var currentWeekSnapshots: [LeagueStepSnapshot] = []

    @Published var activeChallenges: [Challenge] = []


    // ── Future Responsibilities ────────────────────────────────────────────
    // - Initialise SupabaseClient using AppConfig.supabaseUrl / anonKey.
    // - Authenticate via Magic Link; sync session token.
    // - All league CRUD below maps to Supabase PostgreSQL tables:
    //     leagues / league_members / league_step_snapshots


    // MARK: - Auth

    func signIn(email: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // Trigger Supabase OTP/Magic Link login
        completion(.success(true))
    }

    func signOut(completion: @escaping (Error?) -> Void) {
        self.currentUser = nil
        completion(nil)
    }


    // MARK: - League CRUD

    /// Creates a new league, inserts the creator as the admin member, and
    /// generates a unique invite code server-side.
    ///
    /// On success the returned `League` has a real `id` and `inviteCode`.
    /// The creator's `LeagueMember` record (role = .admin) is also created
    /// at the same time inside a Supabase database transaction.
    func createLeague(
        name: String,
        description: String?,
        memberCap: Int?,
        createdBy: UUID,
        completion: @escaping (Result<League, Error>) -> Void
    ) {
        // Stub: generate a placeholder league locally.
        let league = League(
            id: UUID(),
            name: name,
            description: description,
            inviteCode: "STUB42",
            createdBy: createdBy,
            memberCap: memberCap,
            createdAt: Date()
        )
        // Also create the admin membership record (stub — no persistence yet).
        let adminMembership = LeagueMember(
            id: UUID(),
            leagueId: league.id,
            userId: createdBy,
            role: .admin,
            verifiedStepsInLeague: 0,
            currencyEarnedInLeague: 0,
            joinedAt: Date()
        )
        activeLeagues.append(league)
        myMemberships.append(adminMembership)
        completion(.success(league))
    }

    /// Joins an existing league using an invite code.
    /// Looks up the league server-side and inserts a new `league_members` row
    /// with role = .member and joinedAt = now().
    func joinLeague(
        inviteCode: String,
        userId: UUID,
        completion: @escaping (Result<LeagueMember, Error>) -> Void
    ) {
        // Stub: would POST to Supabase RPC `join_league_by_code`.
        // Returns a synthetic membership with zero stats.
        let membership = LeagueMember(
            id: UUID(),
            leagueId: UUID(),         // real impl returns the actual leagueId
            userId: userId,
            role: .member,
            verifiedStepsInLeague: 0,
            currencyEarnedInLeague: 0,
            joinedAt: Date()
        )
        myMemberships.append(membership)
        completion(.success(membership))
    }

    /// Fetches all `LeagueMember` rows for a given league.
    /// Used to populate the member list and leaderboard on the league detail screen.
    func fetchMembers(
        forLeague leagueId: UUID,
        completion: @escaping (Result<[LeagueMember], Error>) -> Void
    ) {
        // Stub: returns an empty list until Supabase is wired.
        activeMembership = []
        completion(.success([]))
    }

    /// Fetches all leagues the current user belongs to.
    func fetchMyLeagues(completion: @escaping (Result<[League], Error>) -> Void) {
        // Stub: reads from `league_members` joined to `leagues`.
        completion(.success(activeLeagues))
    }


    // MARK: - In-League Step & Currency Tracking

    /// Updates a member's cumulative in-league step total and derived currency
    /// after a new verified step batch is imported from HealthKit.
    ///
    /// - Parameters:
    ///   - additionalSteps: The new verified steps to add to the running total.
    ///   - memberId: The `LeagueMember.id` row to update.
    func addVerifiedSteps(
        additionalSteps: Int,
        toMember memberId: UUID,
        completion: @escaping (Result<LeagueMember, Error>) -> Void
    ) {
        // Stub: would PATCH `league_members` SET
        //   verified_steps_in_league = verified_steps_in_league + additionalSteps,
        //   currency_earned_in_league = floor(verified_steps_in_league / stepsPerUnit)
        guard let idx = myMemberships.firstIndex(where: { $0.id == memberId }) else { return }
        let stepsPerUnit = AppConfig.stepsPerCurrencyUnit
        myMemberships[idx].verifiedStepsInLeague += additionalSteps
        myMemberships[idx].currencyEarnedInLeague =
            Int(Double(myMemberships[idx].verifiedStepsInLeague) / stepsPerUnit)
        completion(.success(myMemberships[idx]))
    }


    // MARK: - Weekly Step Snapshots

    /// Submits a weekly verified-step snapshot for one member of a league.
    /// Called at the end of each ISO week (Sunday midnight) by a background job.
    ///
    /// The snapshot freezes the week's step and currency totals so the
    /// leaderboard history is immutable even if raw HealthKit data changes later.
    func submitWeeklySnapshot(
        leagueId: UUID,
        userId: UUID,
        weekStart: Date,
        weekEnd: Date,
        verifiedSteps: Int,
        completion: @escaping (Result<LeagueStepSnapshot, Error>) -> Void
    ) {
        let currencyEarned = Int(Double(verifiedSteps) / AppConfig.stepsPerCurrencyUnit)
        let snapshot = LeagueStepSnapshot(
            id: UUID(),
            leagueId: leagueId,
            userId: userId,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            verifiedSteps: verifiedSteps,
            currencyEarned: currencyEarned,
            calculatedAt: Date()
        )
        currentWeekSnapshots.append(snapshot)
        completion(.success(snapshot))
    }

    /// Fetches all snapshots for a league in the current week.
    /// The leaderboard sorts these by verifiedSteps descending.
    func fetchCurrentWeekSnapshots(
        forLeague leagueId: UUID,
        completion: @escaping (Result<[LeagueStepSnapshot], Error>) -> Void
    ) {
        // Stub: would SELECT from league_step_snapshots WHERE league_id = leagueId
        // AND week_start_date = current ISO week start.
        let results = currentWeekSnapshots.filter { $0.leagueId == leagueId }
        completion(.success(results))
    }


    // MARK: - Challenge Methods

    /// Sends a new challenge invite.
    /// Locks `challengerWager` from the challenger's balance immediately.
    /// The opponent's wager is locked when they accept (status → .active).
    func createChallenge(
        challengerId: UUID,
        opponentId: UUID,
        leagueId: UUID?,
        type: ChallengeType,
        stepGoal: Int?,
        durationHours: Int,
        challengerWager: Int,
        opponentWager: Int,
        completion: @escaping (Result<Challenge, Error>) -> Void
    ) {
        // Stub: would INSERT into `challenges` and debit challengerWager
        // from the challenger's currency_transactions.
        let challenge = Challenge(
            id: UUID(),
            challengerId: challengerId,
            opponentId: opponentId,
            leagueId: leagueId,
            type: type,
            stepGoal: stepGoal,
            durationHours: durationHours,
            challengerWager: challengerWager,
            opponentWager: opponentWager,
            challengerSteps: 0,
            opponentSteps: 0,
            status: .invited,
            winnerId: nil,
            challengerFinalSteps: nil,
            opponentFinalSteps: nil,
            createdAt: Date(),
            startedAt: nil,
            endsAt: nil
        )
        activeChallenges.append(challenge)
        completion(.success(challenge))
    }

    /// Called by the opponent to accept a pending challenge.
    /// Sets status → .active and locks the opponent's wager.
    func acceptChallenge(
        challengeId: UUID,
        completion: @escaping (Result<Challenge, Error>) -> Void
    ) {
        // Stub: would PATCH status = 'active', started_at = now(),
        // ends_at = now() + duration, debit opponentWager.
        guard let idx = activeChallenges.firstIndex(where: { $0.id == challengeId }) else { return }
        activeChallenges[idx].status = .active
        completion(.success(activeChallenges[idx]))
    }

    /// Updates the live step count for one participant mid-challenge.
    /// Called each time a new HealthKit batch is imported.
    func updateLiveSteps(
        challengeId: UUID,
        challengerSteps: Int?,
        opponentSteps: Int?,
        completion: @escaping (Result<Challenge, Error>) -> Void
    ) {
        // Stub: would PATCH challenger_steps / opponent_steps columns.
        guard let idx = activeChallenges.firstIndex(where: { $0.id == challengeId }) else { return }
        if let cs = challengerSteps { activeChallenges[idx].challengerSteps = cs }
        if let os = opponentSteps  { activeChallenges[idx].opponentSteps  = os }
        completion(.success(activeChallenges[idx]))
    }

    /// Resolves a completed challenge: sets status → .completed, records
    /// winner, final steps, and triggers currency payout transactions.
    func resolveChallenge(
        challengeId: UUID,
        winnerId: UUID,
        challengerFinalSteps: Int,
        opponentFinalSteps: Int,
        completion: @escaping (Result<Challenge, Error>) -> Void
    ) {
        // Stub: would PATCH status, winner_id, final step columns, then call
        // server-side RPC `settle_challenge_payouts` which credits the winner
        // and debits losers, then resolves all Stake records on this challenge.
        guard let idx = activeChallenges.firstIndex(where: { $0.id == challengeId }) else { return }
        activeChallenges[idx].status = .completed
        completion(.success(activeChallenges[idx]))
    }

    /// Subscribes to real-time step updates for an active challenge via
    /// Supabase Realtime (Postgres CDC). Fires the handler on each update.
    func subscribeToChallengeUpdates(
        challengeId: UUID,
        onUpdate: @escaping (Challenge) -> Void
    ) {
        // Stub: would open a Supabase Realtime channel on
        // challenges WHERE id = challengeId.
    }


    // MARK: - Stake (Spectator Betting) Methods

    /// Places a virtual side-bet on a challenge.
    /// The staker picks a predicted winner and locks `amountWagered` currency.
    ///
    /// Business rule: staker must NOT be the challenger or opponent.
    /// Validation happens server-side to prevent cheating.
    func placeStake(
        challengeId: UUID,
        stakerId: UUID,
        predictedWinnerId: UUID,
        amountWagered: Int,
        completion: @escaping (Result<Stake, Error>) -> Void
    ) {
        // Stub: would INSERT into `stakes` and debit amountWagered
        // from staker's currency_transactions (type = .staked).
        let stake = Stake(
            id: UUID(),
            challengeId: challengeId,
            stakerId: stakerId,
            predictedWinnerId: predictedWinnerId,
            amountWagered: amountWagered,
            isResolved: false,
            won: nil,
            payoutReceived: nil,
            placedAt: Date(),
            resolvedAt: nil
        )
        completion(.success(stake))
    }

    /// Fetches all stakes placed on a specific challenge.
    /// Used to show the spectator pool size and odds on the challenge detail screen.
    func fetchStakes(
        forChallenge challengeId: UUID,
        completion: @escaping (Result<[Stake], Error>) -> Void
    ) {
        // Stub: SELECT * FROM stakes WHERE challenge_id = challengeId
        completion(.success([]))
    }

    /// Settles all stakes on a challenge after it resolves.
    /// Winners receive proportional payouts from the pool of losing stakes.
    /// Called automatically by `resolveChallenge` server-side.
    func settleStakes(
        forChallenge challengeId: UUID,
        winnerId: UUID,
        completion: @escaping (Result<[Stake], Error>) -> Void
    ) {
        // Stub: would call Supabase RPC `settle_stakes(challenge_id, winner_id)`
        // which computes pari-mutuel payouts and writes currency_transactions.
        completion(.success([]))
    }
}


