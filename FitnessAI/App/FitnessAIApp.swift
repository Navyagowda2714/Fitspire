//
//  FitnessAIApp.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import SwiftUI
import SwiftData

@main
struct FitnessAIApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
        .modelContainer(for: [
            UserProfile.self,
            BodyScanResult.self,
            WorkoutPlan.self
        ])
    }
}
