//
//  ExerciseDemoView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 05/05/2026.
//


import SwiftUI

struct ExerciseDemoView: View {
    let exercise: ExerciseType
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var animating = false

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {

                // Top bar with back button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.vertical, 8)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)

                // Demo animation area
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "1A1A1A"))
                        .padding(.horizontal, 24)

                    VStack(spacing: 20) {
                        ExerciseAnimationView(exercise: exercise)
                            .frame(height: 200)
                            .padding(.horizontal, 40)

                        Text("Watch the demonstration")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .frame(height: 280)
                .padding(.top, 12)

                // Exercise info
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.rawValue)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            Text(exercise.targetMuscles)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.top, 20)

                        // Stats row
                        HStack(spacing: 10) {
                            InfoPill(icon: "repeat",
                                     text: exercise.targetReps)
                            InfoPill(icon: "timer",
                                     text: exercise.restTime)
                            InfoPill(icon: "bolt.fill",
                                     text: exercise.difficulty)
                        }

                        // Key form points
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Key form points")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))

                            ForEach(exercise.formPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "1D9E75"))
                                        .padding(.top, 1)
                                    Text(point)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .lineSpacing(3)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Common mistakes
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Common mistakes to avoid")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))

                            ForEach(exercise.commonMistakes, id: \.self) { mistake in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "D85A30"))
                                        .padding(.top, 1)
                                    Text(mistake)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .lineSpacing(3)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 24)
                }
            }

            // Start button pinned to bottom
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.clear, Color(hex: "0D0D0D")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)

                    Button(action: onStart) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 18))
                            Text("Start with camera")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: "7F77DD"),
                                    Color(hex: "534AB7")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(
                            color: Color(hex: "7F77DD").opacity(0.4),
                            radius: 12, x: 0, y: 6
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .background(Color(hex: "0D0D0D"))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { animating = true }
    }
}

// MARK: - Supporting views

struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "7F77DD"))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }
}

// MARK: - ExerciseType extensions

extension ExerciseType {
    var demoIcon: String {
        switch self {
        case .squat:         return "figure.strengthtraining.traditional"
        case .plank:         return "figure.core.training"
        case .pushUp:        return "figure.highintensity.intervaltraining"
        case .shoulderPress: return "figure.arms.open"
        case .deadlift:      return "figure.strengthtraining.functional"
        case .general:       return "figure.walk"
        }
    }

    var targetMuscles: String {
        switch self {
        case .squat:         return "Quads · Glutes · Hamstrings · Core"
        case .plank:         return "Core · Shoulders · Back"
        case .pushUp:        return "Chest · Triceps · Shoulders · Core"
        case .shoulderPress: return "Shoulders · Triceps · Upper back"
        case .deadlift:      return "Back · Hamstrings · Glutes · Core"
        case .general:       return "Full body"
        }
    }

    var formPoints: [String] {
        switch self {
        case .squat:
            return [
                "Feet shoulder-width apart, toes slightly out",
                "Keep knees aligned over toes throughout",
                "Chest up, back neutral, core braced",
                "Lower until thighs are parallel to floor"
            ]
        case .plank:
            return [
                "Forearms flat, elbows directly under shoulders",
                "Body forms a straight line from head to heel",
                "Core tight — hips neither sagging nor raised",
                "Hold steady and breathe throughout"
            ]
        case .pushUp:
            return [
                "Hands shoulder-width apart, fingers pointing forward",
                "Elbows at 45 degrees — not flared wide",
                "Body in a straight line from head to heel",
                "Lower until chest nearly touches the floor"
            ]
        case .shoulderPress:
            return [
                "Grip just outside shoulder width",
                "Core braced, lower back neutral — no arch",
                "Press directly overhead, arms fully extended",
                "Lower bar to chin level with control"
            ]
        case .deadlift:
            return [
                "Bar over mid-foot, shoulder-width grip",
                "Hinge at hips — back flat, chest proud",
                "Push the floor away — do not pull with back",
                "Drive hips forward at the top of the lift"
            ]
        case .general:
            return [
                "Move with control — no rushing",
                "Breathe steadily throughout",
                "Stop if you feel any pain or discomfort"
            ]
        }
    }

    var commonMistakes: [String] {
        switch self {
        case .squat:
            return [
                "Knees caving inward during the descent",
                "Heels lifting off the ground",
                "Rounding the lower back at the bottom"
            ]
        case .plank:
            return [
                "Letting hips sag toward the floor",
                "Raising hips too high into a pike",
                "Holding your breath instead of breathing"
            ]
        case .pushUp:
            return [
                "Flaring elbows out to 90 degrees",
                "Hips sagging or raising during the rep",
                "Not achieving full range of motion"
            ]
        case .shoulderPress:
            return [
                "Arching the lower back excessively",
                "Using leg drive to push the bar up",
                "Pressing in front of the body not overhead"
            ]
        case .deadlift:
            return [
                "Rounding the lower back under load",
                "Jerking the bar off the floor",
                "Letting the bar drift away from the body"
            ]
        case .general:
            return [
                "Moving too fast and losing control",
                "Skipping the warm-up",
                "Training through sharp pain"
            ]
        }
    }

    var targetReps: String {
        switch self {
        case .squat:         return "8–12 reps"
        case .plank:         return "30–60 sec"
        case .pushUp:        return "8–15 reps"
        case .shoulderPress: return "8–12 reps"
        case .deadlift:      return "5–8 reps"
        case .general:       return "3 sets"
        }
    }

    var restTime: String { "60–90 sec" }

    var difficulty: String {
        switch self {
        case .squat, .pushUp, .plank: return "Beginner"
        case .shoulderPress:          return "Intermediate"
        case .deadlift:               return "Intermediate"
        case .general:                return "Any level"
        }
    }

    var targetRepCount: Int {
        switch self {
        case .squat, .pushUp, .shoulderPress: return 10
        case .plank:                          return 1
        case .deadlift:                       return 6
        case .general:                        return 10
        }
    }
}
