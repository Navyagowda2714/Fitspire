//
//  WorkoutDashboardView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//
import SwiftUI
import Combine

struct WorkoutDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLiveWorkout = false
    @State private var selectedExercise: ExerciseType = .squat

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good morning")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text(appState.userProfile?.name ?? "Athlete")
                            .font(.system(size: 28, weight: .medium))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Today card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(appState.selectedGoal?.rawValue ?? "Training day")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color(hex: "3C3489"))
                            Text("Select an exercise and start your session")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "534AB7").opacity(0.8))

                            // Exercise picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ExerciseType.allCases, id: \.self) { exercise in
                                        if exercise != .general {
                                            Button {
                                                selectedExercise = exercise
                                            } label: {
                                                Text(exercise.rawValue)
                                                    .font(.system(size: 12, weight:
                                                        selectedExercise == exercise
                                                        ? .medium : .regular
                                                    ))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 7)
                                                    .background(
                                                        selectedExercise == exercise
                                                        ? Color(hex: "534AB7")
                                                        : Color(hex: "534AB7").opacity(0.15)
                                                    )
                                                    .foregroundStyle(
                                                        selectedExercise == exercise
                                                        ? Color.white
                                                        : Color(hex: "534AB7")
                                                    )
                                                    .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            Button {
                                showLiveWorkout = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.viewfinder")
                                    Text("Start \(selectedExercise.rawValue)")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color(hex: "7F77DD"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "EEEDFE"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                    }

                    // Quick start section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick start")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)

                        VStack(spacing: 8) {
                            ForEach(ExerciseType.allCases, id: \.self) { exercise in
                                if exercise != .general {
                                    Button {
                                        selectedExercise = exercise
                                        showLiveWorkout  = true
                                    } label: {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(hex: "EEEDFE"))
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: exerciseIcon(exercise))
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(Color(hex: "534AB7"))
                                            }
                                            Text(exercise.rawValue)
                                                .font(.system(size: 14))
                                                .foregroundStyle(Color.primary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 56)
                                        .background(Color(.systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.primary.opacity(0.08),
                                                        lineWidth: 0.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showLiveWorkout) {
                LiveWorkoutView(exercise: selectedExercise)
            }
        }
    }

    func exerciseIcon(_ exercise: ExerciseType) -> String {
        switch exercise {
        case .squat:         return "figure.strengthtraining.traditional"
        case .plank:         return "figure.core.training"
        case .pushUp:        return "figure.highintensity.intervaltraining"
        case .shoulderPress: return "figure.arms.open"
        case .deadlift:      return "figure.strengthtraining.functional"
        case .general:       return "figure.walk"
        }
    }
}
