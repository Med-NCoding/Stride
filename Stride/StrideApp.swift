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
    @StateObject private var stateManager = AppStateManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stateManager)
                .task {
                    // Listen to the Supabase auth state stream.
                    //
                    // authStateChanges is an AsyncStream that emits every time
                    // the session status changes: sign-in, sign-out, token refresh,
                    // or expiry. By observing it here at the root we can react to
                    // external sign-outs (e.g. token revoked from the Dashboard)
                    // and automatically push the UI back to the signed-out screen.
                    for await (event, _) in await supabase.auth.authStateChanges {
                        switch event {
                        case .signedOut:
                            // External sign-out (token revoked / expired server-side).
                            // Only update state if we're not already showing the auth screen
                            // to avoid an animation flash during our own signOut() call.
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
