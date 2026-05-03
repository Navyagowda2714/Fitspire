//
//  MainTabView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            WorkoutDashboardView()
                .tabItem {
                    Label("Home", systemImage: "square.grid.2x2")
                }
            WorkoutPlanView()
                .tabItem {
                    Label("Plan", systemImage: "list.bullet.clipboard")
                }
            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
            Text("Progress — Phase 12")
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(Color(hex: "7F77DD"))
    }
}
