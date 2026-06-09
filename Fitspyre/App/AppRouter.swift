//
//  AppRouter.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 28/04/2026.
//



import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.hasSeenIntro {
                // Step 1 — animated intro slides (first launch only)
                IntroView {
                    appState.markIntroSeen()
                }
            } else if !appState.hasAcceptedTerms {
                // Step 2 — injury / medical disclaimer (must accept once)
                TermsAndConditionsView {
                    appState.markTermsAccepted()
                }
            } else if !appState.isAuthenticated {
                // Step 3 — Sign in with Apple / Face ID
                LoginView()
            } else {
                // Step 4 — straight into the app, no questionnaire
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.hasSeenIntro)
        .animation(.easeInOut(duration: 0.35), value: appState.hasAcceptedTerms)
        .animation(.easeInOut(duration: 0.35), value: appState.isAuthenticated)
    }
}
