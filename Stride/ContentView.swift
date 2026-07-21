import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var stateManager: AppStateManager
    @State private var selectedTab: StrideTab = .home

    var body: some View {
        Group {
            switch stateManager.rootState {
            case .loading:
                AppLoadingView()
            case .signedOut, .onboardingRequired:
                AuthOnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .signedIn:
                mainApp
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: stateManager.rootState)
        .task {
            // Initiate session loading/restore on mount
            await stateManager.startInitialLoading()
        }
    }

    private var mainApp: some View {
        ZStack(alignment: .bottom) {
            // Active tab content
            Group {
                switch selectedTab {
                case .home:       HomeView()
                case .leagues:    LeaguesView()
                case .challenges: ChallengesView()
                case .recap:      WeeklyRecapView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)

            // Floating custom tab bar
            StrideTabBar(selected: $selectedTab)
                .padding(.bottom, 12)
        }
        .background(SD.bgPrimary.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateManager())
        .preferredColorScheme(.dark)
}
