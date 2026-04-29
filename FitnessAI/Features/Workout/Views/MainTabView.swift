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
            Text("Dashboard — coming in Phase 8")
                .tabItem {
                    Label("Home", systemImage: "square.grid.2x2")
                }
            Text("Nutrition — coming in Phase 9")
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
            Text("Progress — coming in Phase 12")
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
            Text("Settings — coming in Phase 12")
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Color(hex: "7F77DD"))
    }
}
