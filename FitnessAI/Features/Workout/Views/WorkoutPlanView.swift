//
//  WorkoutPlanView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//


import SwiftUI
import SwiftData

struct WorkoutPlanView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @State private var expandedDay: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let plan = viewModel.generatedPlan {
                    planView(plan: plan)
                } else {
                    generateView
                }
            }
            .navigationTitle("Your plan")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if viewModel.generatedPlan == nil {
                loadPlan()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(Color(hex: "7F77DD"))
            Text("Building your personalised plan...")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }

    private var generateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "7F77DD"))
            Text("No plan yet")
                .font(.system(size: 18, weight: .medium))
            Button {
                loadPlan()
            } label: {
                Text("Generate my plan")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 48)
                    .background(Color(hex: "7F77DD"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func planView(plan: GeneratedWorkoutPlan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Plan header
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.goal.rawValue)
                        .font(.system(size: 22, weight: .medium))
                    Text(plan.splitType)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Stats row
                HStack(spacing: 10) {
                    PlanStatCard(
                        value: "\(plan.weeklyFrequency)x",
                        label: "Per week"
                    )
                    PlanStatCard(
                        value: "\(plan.timelineMonths) mo",
                        label: "Timeline"
                    )
                    PlanStatCard(
                        value: "\(plan.workoutDays.filter { !$0.isRestDay }.count)",
                        label: "Workouts"
                    )
                }
                .padding(.horizontal, 24)

                // Weekly schedule
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly schedule")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)

                    ForEach(plan.workoutDays) { day in
                        WorkoutDayRow(
                            day: day,
                            isExpanded: expandedDay == day.id
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expandedDay = expandedDay == day.id ? nil : day.id
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                // Progression note
                VStack(alignment: .leading, spacing: 6) {
                    Text("Progression plan")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(plan.progressionNote)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .padding(14)
                .background(Color(hex: "EEEDFE"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

                // Safety notes
                if !plan.safetyNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Safety notes")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)

                        ForEach(plan.safetyNotes, id: \.self) { note in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "1D9E75"))
                                Text(note)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
    }

    private func loadPlan() {
        guard let goal = appState.selectedGoal else { return }
        viewModel.generatePlan(
            goal: goal,
            experience: appState.userProfile?.experienceLevel ?? "beginner",
            injuries: appState.userProfile?.injuries ?? [],
            postureScore: 80
        )
    }
}

struct PlanStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color(hex: "534AB7"))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: "EEEDFE"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WorkoutDayRow: View {
    let day: WorkoutDay
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(day.isRestDay
                                  ? Color(.systemGray6)
                                  : Color(hex: "EEEDFE"))
                            .frame(width: 44, height: 44)
                        Text(String(day.dayName.prefix(3)))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(day.isRestDay
                                             ? Color.secondary
                                             : Color(hex: "534AB7"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.focusArea)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.primary)
                        if !day.isRestDay {
                            Text("\(day.exercises.count) exercises · \(day.estimatedMinutes) min")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if !day.isRestDay {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            if isExpanded && !day.isRestDay {
                VStack(spacing: 0) {
                    ForEach(day.exercises) { exercise in
                        HStack(spacing: 12) {
                            Text(exercise.name)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Text("\(exercise.sets) × \(exercise.reps)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                        if exercise.id != day.exercises.last?.id {
                            Divider()
                                .padding(.leading, 14)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 4)
            }
        }
    }
}
