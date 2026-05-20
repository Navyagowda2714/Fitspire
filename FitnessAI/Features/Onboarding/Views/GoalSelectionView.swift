//
//  GoalSelectionView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

//  GoalSelectionView.swift — FitnessAI
//
//  GoalSelectionView.swift
//  FitnessAI
//

//
//  GoalSelectionView.swift
//  FitnessAI
//

import SwiftUI

struct GoalSelectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var selected: FitnessGoal?

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Let's build your plan!").font(.system(size: 14)).foregroundStyle(Color.appT3)
                    // FIX: iOS 26 Text interpolation
                    Text("What is your \(Text("fitness goal?").foregroundStyle(Color.appCyan))")
                        .font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
                }
                .padding(.horizontal, 28).padding(.top, 60).padding(.bottom, 28)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(FitnessGoal.allCases) { goal in
                            GoalRow(goal: goal, isSelected: selected == goal) { selected = goal }
                        }
                    }.padding(.horizontal, 28).padding(.bottom, 130)
                }
            }
        }
        .overlay(alignment: .bottom) {
            Button {
                guard let goal = selected else { return }
                appState.markGoalComplete(goal: goal)
            } label: {
                HStack {
                    Text("Build my plan").font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(selected != nil ? .black : Color.appT3)
                    Spacer()
                    Image(systemName: "arrow.right").font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(selected != nil ? .black : Color.appT3)
                }
                .padding(.horizontal, 28).frame(maxWidth: .infinity).frame(height: 58)
                .background(selected != nil ? Color.appCyan : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(selected != nil ? Color.appCyan : Color.appHair2, lineWidth: 1.5))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .animation(.easeInOut(duration: 0.2), value: selected != nil)
            }
            .disabled(selected == nil)
            .padding(.horizontal, 28).padding(.bottom, 44).padding(.top, 16)
            .background(LinearGradient(colors: [Color.appBG.opacity(0), Color.appBG],
                                        startPoint: .top, endPoint: .bottom))
        }
    }
}

struct GoalRow: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.rawValue).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    Text(goal.subtitle).font(.system(size: 12)).foregroundStyle(Color.appT3)
                }
                Spacer()
                ZStack {
                    Circle().stroke(isSelected ? Color.appCyan : Color.appHair2, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected { Circle().fill(Color.appCyan).frame(width: 12, height: 12) }
                }
            }
            .padding(16).background(isSelected ? Color.appCyan.opacity(0.08) : Color.appBG2)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.appCyan.opacity(0.5) : Color.appHair, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
