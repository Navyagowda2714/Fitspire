//
//  WorkoutDashboardView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//  WorkoutDashboardView.swift — FitnessAI
import SwiftUI
import Combine

struct WorkoutDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLiveWorkout  = false
    @State private var selectedExercise: ExerciseType = .squat
    @State private var showDemo         = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formattedDate())
                                    .font(.system(size: 11, weight: .bold)).kerning(0.6)
                                    .foregroundStyle(Color.appT3)
                                Text("Hey, \(appState.userProfile?.name ?? "Athlete")")
                                    .font(.system(size: 30, weight: .heavy)).foregroundStyle(.white)
                            }
                            Spacer()
                            ZStack {
                                Circle().fill(Color.appBG2).frame(width: 40, height: 40)
                                Image(systemName: "bell.fill").font(.system(size: 16)).foregroundStyle(Color.appLime)
                            }
                        }
                        .padding(.horizontal, 24).padding(.top, 16)

                        // Today card
                        VStack(alignment: .leading, spacing: 4) {
                            Text("UP NEXT").font(.system(size: 11, weight: .bold))
                                .kerning(1.4).foregroundStyle(Color.appLime).padding(.horizontal, 24)

                            VStack(alignment: .leading, spacing: 14) {
                                Text(appState.selectedGoal?.rawValue ?? "Training day")
                                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                                Text("Select an exercise and start your session")
                                    .font(.system(size: 13)).foregroundStyle(Color.appT3)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(ExerciseType.allCases, id: \.self) { exercise in
                                            if exercise != .general {
                                                Button { selectedExercise = exercise } label: {
                                                    Text(exercise.rawValue)
                                                        .font(.system(size: 12,
                                                            weight: selectedExercise == exercise ? .bold : .regular))
                                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                                        .background(selectedExercise == exercise ? Color.appLime : Color.appBG3)
                                                        .foregroundStyle(selectedExercise == exercise ? .black : Color.appT2)
                                                        .clipShape(Capsule())
                                                }.buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }

                                Button { showDemo = true } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "camera.viewfinder")
                                        Text("Start \(selectedExercise.rawValue)")
                                    }
                                    .font(.system(size: 15, weight: .bold)).foregroundStyle(.black)
                                    .frame(maxWidth: .infinity).frame(height: 50)
                                    .background(Color.appLime).clipShape(Capsule())
                                    .shadow(color: Color.appLime.opacity(0.4), radius: 12, y: 4)
                                }
                            }
                            .padding(18)
                            .background(Color.appBG2)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.appHair, lineWidth: 0.5))
                            .padding(.horizontal, 24)
                        }

                        // Quick start
                        VStack(alignment: .leading, spacing: 10) {
                            Text("QUICK START").font(.system(size: 11, weight: .bold))
                                .kerning(1.4).foregroundStyle(Color.appT3).padding(.horizontal, 24)

                            VStack(spacing: 8) {
                                ForEach(ExerciseType.allCases, id: \.self) { exercise in
                                    if exercise != .general {
                                        Button {
                                            selectedExercise = exercise
                                            showLiveWorkout  = true
                                        } label: {
                                            HStack(spacing: 14) {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(Color.appBG3).frame(width: 40, height: 40)
                                                    Image(systemName: exerciseIcon(exercise))
                                                        .font(.system(size: 17)).foregroundStyle(Color.appLime)
                                                }
                                                Text(exercise.rawValue)
                                                    .font(.system(size: 15, weight: .medium)).foregroundStyle(.white)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12)).foregroundStyle(Color.appT4)
                                            }
                                            .padding(.horizontal, 16).frame(height: 58)
                                            .background(Color.appBG2)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.appHair, lineWidth: 0.5))
                                        }
                                        .buttonStyle(.plain).padding(.horizontal, 24)
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("").navigationBarHidden(true)
            .fullScreenCover(isPresented: $showDemo) {
                ExerciseDemoView(exercise: selectedExercise) {
                    showDemo = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showLiveWorkout = true }
                }
            }
            .fullScreenCover(isPresented: $showLiveWorkout) {
                LiveWorkoutView(exercise: selectedExercise)
            }
        }
    }

    private func formattedDate() -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE · MMM d"
        return f.string(from: Date()).uppercased()
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
