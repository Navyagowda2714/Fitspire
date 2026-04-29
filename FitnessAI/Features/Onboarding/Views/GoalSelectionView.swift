//
//  GoalSelectionView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import SwiftUI

struct GoalSelectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var selected: FitnessGoal?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Choose your goal")
                    .font(.system(size: 28, weight: .medium))
                Text("Your plan will be personalised around this.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(FitnessGoal.allCases) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: selected == goal
                        ) {
                            selected = goal
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                Button {
                    guard let goal = selected else { return }
                    appState.markGoalComplete(goal: goal)
                } label: {
                    Text("Build my plan")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(selected != nil ? Color(hex: "7F77DD") : Color.secondary.opacity(0.2))
                        .foregroundStyle(selected != nil ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selected == nil)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(.ultraThinMaterial)
        }
    }
}

struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .fill(isSelected ? Color(hex: "7F77DD") : Color.secondary.opacity(0.2))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.primary)
                    Text(goal.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "534AB7"))
                }
            }
            .padding(14)
            .background(
                isSelected
                ? Color(hex: "EEEDFE")
                : Color(.systemBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color(hex: "534AB7") : Color.primary.opacity(0.08),
                        lineWidth: isSelected ? 1 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
