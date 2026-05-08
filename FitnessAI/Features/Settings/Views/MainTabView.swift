//
//  MainTabView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 06/05/2026.
//

//  MainTabView.swift — FitnessAI
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            WorkoutDashboardView()
                .tabItem { Label("Home",      systemImage: "house.fill") }
            WorkoutPlanView()
                .tabItem { Label("Train",     systemImage: "dumbbell.fill") }
            NutritionView()
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }
            ProgressView()
                .tabItem { Label("Progress",  systemImage: "chart.line.uptrend.xyaxis") }
            SettingsView()
                .tabItem { Label("You",       systemImage: "person.fill") }
        }
        .tint(.appLime)
        .preferredColorScheme(.dark)
        .onAppear {
            let bar = UITabBarAppearance()
            bar.configureWithOpaqueBackground()
            bar.backgroundColor = UIColor(Color.appBG1.opacity(0.92))
            bar.backgroundEffect  = UIBlurEffect(style: .systemUltraThinMaterialDark)
            bar.shadowColor       = UIColor(white: 1, alpha: 0.08)
            UITabBar.appearance().standardAppearance   = bar
            UITabBar.appearance().scrollEdgeAppearance = bar
        }
    }
}
