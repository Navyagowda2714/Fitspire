//
//  GoalSelectionView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

//  GoalSelectionView.swift — FitnessAI
import SwiftUI

struct GoalSelectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var selected: FitnessGoal?

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WHAT'S YOUR GOAL")
                        .font(.system(size: 11, weight: .bold)).kerning(1.4).foregroundStyle(Color.appLime)
                    Text("Choose your goal")
                        .font(.system(size: 30, weight: .heavy)).foregroundStyle(.white)
                    Text("Your plan will be personalised around this.")
                        .font(.system(size: 14)).foregroundStyle(Color.appT3)
                }
                .padding(.horizontal, 24).padding(.top, 60).padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(FitnessGoal.allCases) { goal in
                            GoalCard(goal: goal, isSelected: selected == goal) { selected = goal }
                        }
                    }.padding(.horizontal, 24).padding(.bottom, 120)
                }
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                Button {
                    guard let goal = selected else { return }
                    appState.markGoalComplete(goal: goal)
                } label: {
                    Text("Build my plan")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(selected != nil ? Color.appLime : Color.appBG3)
                        .foregroundStyle(selected != nil ? .black : Color.appT3)
                        .clipShape(Capsule())
                }
                .disabled(selected == nil)
            }
            .padding(.horizontal, 24).padding(.bottom, 32).padding(.top, 16)
            .background(LinearGradient(colors: [Color.appBG.opacity(0), Color.appBG],
                                        startPoint: .top, endPoint: .bottom))
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
                Circle().fill(isSelected ? Color.appLime : Color.appBG3).frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.rawValue).font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                    Text(goal.subtitle).font(.system(size: 12)).foregroundStyle(Color.appT3)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20)).foregroundStyle(Color.appLime)
                }
            }
            .padding(16)
            .background(isSelected ? Color.appLime.opacity(0.10) : Color.appBG2)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.appLime.opacity(0.6) : Color.appHair, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}
