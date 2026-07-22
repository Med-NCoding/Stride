//
//  StrideApp.swift
//  Stride
//
//  Created by Medhansh Negi on 2026-07-20.
//

import SwiftUI
import Supabase

@main
struct StrideApp: App {
    @StateObject private var stateManager  = AppStateManager()
    @StateObject private var healthService = HealthKitService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stateManager)
                .environmentObject(healthService)
                .task {
                    // Check if HealthKit is already authorized on cold launch
                    // so we can show live step data without re-prompting the user.
                    healthService.refreshAuthStatus()

                    // Listen to the Supabase auth state stream.
                    for await (event, _) in await supabase.auth.authStateChanges {
                        switch event {
                        case .signedOut:
                            if stateManager.rootState != .signedOut {
                                await stateManager.signOut()
                            }
                        default:
                            break
                        }
                    }
                }
        }
    }
}
