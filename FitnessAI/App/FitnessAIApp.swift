//
//  FitnessAIApp.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//


import SwiftUI

@main
struct FitnessAIApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
