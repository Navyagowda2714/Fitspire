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
    @State private var showSplash = true   // always show splash on launch

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                } else {
                    RootView()
                        .environmentObject(appState)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showSplash)
        }
        .modelContainer(for: UserProfile.self)
    }
}
