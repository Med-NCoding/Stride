import Foundation
import HealthKit
import Combine

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HealthKitService
//
// Owns all HealthKit interactions for the Stride app:
//
//   1. Availability check  — is HealthKit supported on this device?
//   2. Authorization       — ask the user to allow step-count read access.
//   3. Today's steps       — live query for today (midnight → now).
//   4. Weekly steps        — sum of the last 7 days.
//   5. Background delivery — live observer query so the count updates while
//                            the app is in the foreground (background delivery
//                            requires a separate HKObserverQuery + BGTask,
//                            which is wired up when real leagues are built).
//
// All published properties are updated on the main thread so SwiftUI views
// can observe them safely.
// ─────────────────────────────────────────────────────────────────────────────

// Possible states of the HealthKit permission flow
enum HealthKitStatus {
    case notDetermined   // User has not been asked yet
    case notAvailable    // Device does not support HealthKit (e.g. iPad without HK)
    case denied          // User explicitly denied access
    case authorized      // Read access granted
}

@MainActor
final class HealthKitService: ObservableObject {

    // ── Published State ───────────────────────────────────────────────────
    @Published var status: HealthKitStatus = .notDetermined
    @Published var todaySteps: Int   = 0
    @Published var weeklySteps: Int  = 0
    @Published var previousWeekSteps: Int = 0
    @Published var dailyStepsPastWeek: [Int] = Array(repeating: 0, count: 7)

    // Convenience shorthand used in the health onboarding card
    var isAuthorized: Bool { status == .authorized }

    /// Real calculated percentage change vs previous week's total steps.
    var stepBoostPercentage: Double {
        guard previousWeekSteps > 0 else { return 0.0 }
        let diff = Double(weeklySteps - previousWeekSteps)
        return (diff / Double(previousWeekSteps)) * 100.0
    }

    // ── Private ───────────────────────────────────────────────────────────
    private let store = HKHealthStore()

    // The only data type we read — step count
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    // Observer query handle — kept alive for the life of the service
    private var observerQuery: HKObserverQuery?


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Availability
    //
    // HealthKit is unavailable on iPads that lack the HealthKit capability and
    // on all macOS/Simulator targets without a paired phone.
    // The simulator does support HealthKit but returns 0 steps unless you
    // manually add steps via the Health app inside the simulator.
    // ─────────────────────────────────────────────────────────────────────────

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Authorization Request
    //
    // Presents the system permission sheet asking the user to share step data.
    // Calling this when permission is already granted is a no-op (iOS silently
    // returns without showing the sheet again).
    //
    // Returns true if the user granted access, false otherwise.
    // ─────────────────────────────────────────────────────────────────────────

    func requestAuthorization() async -> Bool {
        guard isAvailable else {
            status = .notAvailable
            return false
        }

        // requestAuthorization is completion-handler-based; we bridge to async.
        return await withCheckedContinuation { continuation in
            store.requestAuthorization(
                toShare: [],               // We never write step data
                read: [stepType]
            ) { [weak self] success, _ in
                guard let self else { return }
                Task { @MainActor in
                    if success {
                        self.status = .authorized
                        // Kick off a live fetch now that we have access
                        await self.fetchAllSteps()
                        self.startObserving()
                    } else {
                        // User denied or dismissed — check the actual auth status
                        self.refreshAuthStatus()
                    }
                    continuation.resume(returning: success)
                }
            }
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Refresh Auth Status
    //
    // Reads the current authorization status from the store without prompting.
    // Called on cold launch so we can skip the permission sheet if already granted.
    // ─────────────────────────────────────────────────────────────────────────

    func refreshAuthStatus() {
        guard isAvailable else { status = .notAvailable; return }

        let authStatus = store.authorizationStatus(for: stepType)
        switch authStatus {
        case .sharingAuthorized:
            status = .authorized
            Task { await fetchAllSteps() }
            startObserving()
        case .sharingDenied:
            status = .denied
        default:
            status = .notDetermined
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Step Queries
    // ─────────────────────────────────────────────────────────────────────────

    /// Fetches today's steps, weekly steps, previous week's steps, and past 7 days daily breakdown.
    func fetchAllSteps() async {
        async let today    = fetchSteps(for: todayInterval())
        async let weekly   = fetchSteps(for: weekInterval())
        async let prevWeek = fetchSteps(for: previousWeekInterval())
        async let daily    = fetchDailyStepsForPastWeek()

        let (t, w, pw, d)  = await (today, weekly, prevWeek, daily)
        todaySteps          = t
        weeklySteps         = w
        previousWeekSteps   = pw
        dailyStepsPastWeek  = d
    }

    // Generic step-sum query for any date interval.
    private func fetchSteps(for interval: DateInterval) async -> Int {
        guard isAvailable, status == .authorized else { return 0 }

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: interval.start,
                end:       interval.end,
                options:   .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            store.execute(query)
        }
    }

    private func fetchDailyStepsForPastWeek() async -> [Int] {
        guard isAvailable, status == .authorized else {
            return Array(repeating: 0, count: 7)
        }
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        var results: [Int] = Array(repeating: 0, count: 7)

        for offset in 0..<7 {
            let index = 6 - offset
            let dayStart = cal.date(byAdding: .day, value: -offset, to: todayStart)!
            let dayEnd   = offset == 0 ? Date() : cal.date(byAdding: .day, value: 1, to: dayStart)!
            let interval = DateInterval(start: dayStart, end: dayEnd)
            let steps    = await fetchSteps(for: interval)
            results[index] = steps
        }
        return results
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Live Observer (foreground updates)
    //
    // HKObserverQuery fires whenever the Health store receives new step data
    // (e.g. Apple Watch sync, manual entry). We respond by re-running our
    // fetch so todaySteps stays current while the app is open.
    // ─────────────────────────────────────────────────────────────────────────

    private func startObserving() {
        guard observerQuery == nil else { return } // Only one at a time

        let query = HKObserverQuery(
            sampleType: stepType,
            predicate: nil
        ) { [weak self] _, _, _ in
            guard let self else { return }
            Task { await self.fetchAllSteps() }
        }
        store.execute(query)
        observerQuery = query
    }


    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Date Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private func todayInterval() -> DateInterval {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: Date())
        return DateInterval(start: start, end: Date())
    }

    private func weekInterval() -> DateInterval {
        let cal   = Calendar.current
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date()))!
        return DateInterval(start: start, end: Date())
    }

    private func previousWeekInterval() -> DateInterval {
        let cal   = Calendar.current
        let start = cal.date(byAdding: .day, value: -13, to: cal.startOfDay(for: Date()))!
        let end   = cal.date(byAdding: .day, value: -7, to: cal.startOfDay(for: Date()))!
        return DateInterval(start: start, end: end)
    }
}
