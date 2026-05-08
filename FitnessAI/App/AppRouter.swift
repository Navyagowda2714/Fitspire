//
//  AppRouter.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.isAuthenticated {
                LoginView()
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !appState.hasCompletedProfile || !appState.hasCompletedGoal {
                QuestionnaireView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedGoal)
    }
}
