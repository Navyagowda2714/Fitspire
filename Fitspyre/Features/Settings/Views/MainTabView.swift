//
//  MainTabView.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 06/05/2026.
//
//  MainTabView.swift
//  Fitspyre
//
//
//  MainTabView.swift
//  Fitspyre
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            GoalDashboardView()
                .tabItem {
                    Label("Goal", systemImage: "target")
                }

            WorkoutDashboardView()
                .tabItem {
                    Label("Workout", systemImage: "dumbbell.fill")
                }

            FitProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("You", systemImage: "person.fill")
                }
        }
        .tint(Color.appCyan)
        .preferredColorScheme(.dark)
        .onAppear {
            let bar = UITabBarAppearance()
            bar.configureWithOpaqueBackground()
            bar.backgroundColor = UIColor(Color.appBG1.opacity(0.95))
            bar.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            bar.shadowColor = UIColor(white: 1, alpha: 0.08)
            UITabBar.appearance().standardAppearance   = bar
            UITabBar.appearance().scrollEdgeAppearance = bar
        }
    }
}
