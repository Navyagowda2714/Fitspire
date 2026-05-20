//
//  WorkoutView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 13/05/2026.
//
import SwiftUI

// MARK: - Exercise Model
struct FitnessExercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: String
    let rest: String
    let tip: String
    let muscle: MuscleGroup
    let difficulty: Difficulty

    enum Difficulty: String {
        case beginner     = "Beginner"
        case intermediate = "Intermediate"
        case advanced     = "Advanced"

        var color: Color {
            switch self {
            case .beginner:     return Color(hex: "1D9E75")
            case .intermediate: return Color(hex: "F5A623")
            case .advanced:     return Color(hex: "D85A30")
            }
        }
    }
}

// MARK: - Workout Data
struct WorkoutLibrary {
    static func exercises(for muscle: MuscleGroup, gender: Gender) -> [FitnessExercise] {
        switch muscle {
        case .chest:
            return [
                FitnessExercise(name: "Push-Ups", sets: 4, reps: "12–15", rest: "60s", tip: "Keep core tight, elbows at 45°", muscle: .chest, difficulty: .beginner),
                FitnessExercise(name: "Barbell Bench Press", sets: 4, reps: "8–10", rest: "90s", tip: "Full range of motion, retract scapula", muscle: .chest, difficulty: .intermediate),
                FitnessExercise(name: "Cable Fly", sets: 3, reps: "12", rest: "60s", tip: "Squeeze at peak contraction", muscle: .chest, difficulty: .intermediate)
            ]
        case .back:
            return [
                FitnessExercise(name: "Pull-Ups", sets: 4, reps: "8–12", rest: "90s", tip: "Dead hang to full chin over bar", muscle: .back, difficulty: .intermediate),
                FitnessExercise(name: "Barbell Row", sets: 4, reps: "8–10", rest: "90s", tip: "Neutral spine, pull to lower chest", muscle: .back, difficulty: .intermediate),
                FitnessExercise(name: "Lat Pulldown", sets: 3, reps: "12", rest: "60s", tip: "Lean slightly back, drive elbows down", muscle: .back, difficulty: .beginner)
            ]
        case .shoulders:
            return [
                FitnessExercise(name: "Overhead Press", sets: 4, reps: "8–10", rest: "90s", tip: "Brace core, don't flare ribs", muscle: .shoulders, difficulty: .intermediate),
                FitnessExercise(name: "Lateral Raises", sets: 3, reps: "15", rest: "45s", tip: "Lead with elbows, slight forward lean", muscle: .shoulders, difficulty: .beginner),
                FitnessExercise(name: "Face Pulls", sets: 3, reps: "15–20", rest: "45s", tip: "Pull to forehead, rotate externally", muscle: .shoulders, difficulty: .beginner)
            ]
        case .biceps:
            return [
                FitnessExercise(name: "Barbell Curl", sets: 4, reps: "10–12", rest: "60s", tip: "Elbows fixed at sides, full ROM", muscle: .biceps, difficulty: .beginner),
                FitnessExercise(name: "Hammer Curl", sets: 3, reps: "12", rest: "60s", tip: "Neutral grip, slow eccentric", muscle: .biceps, difficulty: .beginner),
                FitnessExercise(name: "Incline Dumbbell Curl", sets: 3, reps: "10", rest: "60s", tip: "Great stretch at bottom", muscle: .biceps, difficulty: .intermediate)
            ]
        case .triceps:
            return [
                FitnessExercise(name: "Tricep Dips", sets: 4, reps: "12–15", rest: "60s", tip: "Stay upright to target triceps", muscle: .triceps, difficulty: .intermediate),
                FitnessExercise(name: "Skull Crushers", sets: 3, reps: "10–12", rest: "75s", tip: "Lower slowly, elbows in", muscle: .triceps, difficulty: .intermediate),
                FitnessExercise(name: "Cable Pushdown", sets: 3, reps: "15", rest: "45s", tip: "Lock elbows in, full extension", muscle: .triceps, difficulty: .beginner)
            ]
        case .core:
            return [
                FitnessExercise(name: "Plank", sets: 3, reps: "45s hold", rest: "45s", tip: "Neutral spine, breathe steadily", muscle: .core, difficulty: .beginner),
                FitnessExercise(name: "Dead Bug", sets: 3, reps: "10 each side", rest: "45s", tip: "Lower back pressed to floor always", muscle: .core, difficulty: .beginner),
                FitnessExercise(name: "Cable Crunch", sets: 3, reps: "15–20", rest: "45s", tip: "Crunch ribs to hips, not head to knees", muscle: .core, difficulty: .intermediate)
            ]
        case .quads:
            return [
                FitnessExercise(name: "Barbell Squat", sets: 4, reps: "8–10", rest: "120s", tip: "Knees track over toes, chest up", muscle: .quads, difficulty: .intermediate),
                FitnessExercise(name: "Leg Press", sets: 4, reps: "12", rest: "90s", tip: "Don't lock out knees at top", muscle: .quads, difficulty: .beginner),
                FitnessExercise(name: "Bulgarian Split Squat", sets: 3, reps: "10 each", rest: "90s", tip: "Front foot far enough forward", muscle: .quads, difficulty: .advanced)
            ]
        case .hamstrings:
            return [
                FitnessExercise(name: "Romanian Deadlift", sets: 4, reps: "10–12", rest: "90s", tip: "Hinge at hips, soft knee bend", muscle: .hamstrings, difficulty: .intermediate),
                FitnessExercise(name: "Leg Curl", sets: 3, reps: "12–15", rest: "60s", tip: "Curl fully, hold 1s at top", muscle: .hamstrings, difficulty: .beginner),
                FitnessExercise(name: "Good Morning", sets: 3, reps: "10", rest: "75s", tip: "Bar on traps, push hips back", muscle: .hamstrings, difficulty: .advanced)
            ]
        case .glutes:
            return [
                FitnessExercise(name: "Hip Thrust", sets: 4, reps: "12–15", rest: "75s", tip: "Drive through heels, squeeze at top", muscle: .glutes, difficulty: .beginner),
                FitnessExercise(name: "Sumo Squat", sets: 3, reps: "12", rest: "60s", tip: "Wide stance, toes at 45°", muscle: .glutes, difficulty: .beginner),
                FitnessExercise(name: "Cable Kickback", sets: 3, reps: "15 each", rest: "45s", tip: "Slight forward lean, squeeze glute", muscle: .glutes, difficulty: .beginner)
            ]
        case .calves:
            return [
                FitnessExercise(name: "Standing Calf Raise", sets: 4, reps: "20–25", rest: "45s", tip: "Full stretch at bottom, pause at top", muscle: .calves, difficulty: .beginner),
                FitnessExercise(name: "Seated Calf Raise", sets: 3, reps: "20", rest: "45s", tip: "Targets soleus specifically", muscle: .calves, difficulty: .beginner),
                FitnessExercise(name: "Single-Leg Calf Raise", sets: 3, reps: "15 each", rest: "45s", tip: "Hold wall for balance only", muscle: .calves, difficulty: .intermediate)
            ]
        }
    }
}

// MARK: - Main Workout View
struct WorkoutView: View {
    let gender: Gender
    let selectedMuscles: Set<MuscleGroup>

    @State private var completedExercises: Set<UUID> = []
    @State private var expandedMuscle: MuscleGroup? = nil
    @State private var workoutStarted = false
    @Environment(\.dismiss) private var dismiss

    var workoutPlan: [(MuscleGroup, [FitnessExercise])] {
        let ordered = MuscleGroup.allCases.filter { selectedMuscles.contains($0) }
        return ordered.map { muscle in
            (muscle, WorkoutLibrary.exercises(for: muscle, gender: gender))
        }
    }

    var totalExercises: Int {
        workoutPlan.reduce(0) { $0 + $1.1.count }
    }

    var completionPercent: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(completedExercises.count) / Double(totalExercises)
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0E1A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header Card
                    WorkoutHeaderCard(
                        gender: gender,
                        muscles: selectedMuscles,
                        totalExercises: totalExercises,
                        completionPercent: completionPercent,
                        completedCount: completedExercises.count
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    // Exercise Sections
                    ForEach(workoutPlan, id: \.0) { muscle, exercises in
                        MuscleSectionView(
                            muscle: muscle,
                            exercises: exercises,
                            completedExercises: $completedExercises,
                            isExpanded: expandedMuscle == muscle
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                expandedMuscle = expandedMuscle == muscle ? nil : muscle
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }

                    // Finish Button
                    if completionPercent == 1.0 {
                        Button {
                            // Save workout and pop to root
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "trophy.fill")
                                Text("Workout Complete! 🎉")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "1D9E75"), Color(hex: "0d7a5b")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color(hex: "1D9E75").opacity(0.5), radius: 16, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: completionPercent)
                    } else {
                        // Start prompt
                        if !workoutStarted {
                            Button {
                                withAnimation { workoutStarted = true }
                                expandedMuscle = workoutPlan.first?.0
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                    Text("Start Workout")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "7F77DD"), Color(hex: "5a53b0")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        .navigationTitle("Your Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Workout Header Card
struct WorkoutHeaderCard: View {
    let gender: Gender
    let muscles: Set<MuscleGroup>
    let totalExercises: Int
    let completionPercent: Double
    let completedCount: Int

    var focusLabel: String {
        if muscles.count == MuscleGroup.allCases.count { return "Full Body" }
        if muscles.count == 1 { return muscles.first!.rawValue }
        return "\(muscles.count) Muscle Groups"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Plan")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                    Text(focusLabel)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                // Stats
                HStack(spacing: 16) {
                    StatPill(value: "\(totalExercises)", label: "Exercises", icon: "dumbbell.fill")
                    StatPill(value: "\(workoutDuration())m", label: "Est. Time", icon: "clock.fill")
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text("\(completedCount)/\(totalExercises)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [Color(hex: "1D9E75"), Color(hex: "2ABFFF")], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * completionPercent, height: 6)
                            .animation(.spring(response: 0.5), value: completionPercent)
                    }
                }
                .frame(height: 6)
            }

            // Muscle tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(muscles).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { m in
                        Text(m.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(m.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(m.color.opacity(0.15))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(m.color.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }

    func workoutDuration() -> Int {
        // ~3–4 min per exercise on average
        return totalExercises * 4
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "1D9E75"))
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Muscle Section
struct MuscleSectionView: View {
    let muscle: MuscleGroup
    let exercises: [FitnessExercise]
    @Binding var completedExercises: Set<UUID>
    let isExpanded: Bool
    let onToggle: () -> Void

    var doneCount: Int { exercises.filter { completedExercises.contains($0.id) }.count }

    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(muscle.color.opacity(0.25))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: muscle.icon)
                                .font(.system(size: 16))
                                .foregroundColor(muscle.color)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(muscle.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(exercises.count) exercises · \(doneCount) done")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()

                    // Completion indicator
                    if doneCount == exercises.count {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(muscle.color)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(exercises) { exercise in
                        ExerciseRow(
                            exercise: exercise,
                            isDone: completedExercises.contains(exercise.id)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                if completedExercises.contains(exercise.id) {
                                    completedExercises.remove(exercise.id)
                                } else {
                                    completedExercises.insert(exercise.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            isExpanded ? muscle.color.opacity(0.35) : Color.white.opacity(0.07),
                            lineWidth: 1
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isExpanded)
    }
}

// MARK: - Exercise Row
struct ExerciseRow: View {
    let exercise: FitnessExercise
    let isDone: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isDone ? exercise.muscle.color : Color.white.opacity(0.08))
                        .frame(width: 28, height: 28)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(exercise.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isDone ? .white.opacity(0.4) : .white)
                        .strikethrough(isDone, color: .white.opacity(0.3))

                    Spacer()

                    // Difficulty badge
                    Text(exercise.difficulty.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(exercise.difficulty.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(exercise.difficulty.color.opacity(0.15))
                        .clipShape(Capsule())
                }

                HStack(spacing: 16) {
                    Label("\(exercise.sets) sets × \(exercise.reps)", systemImage: "repeat")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                    Label(exercise.rest + " rest", systemImage: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                }

                // Coach tip
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "F5A623"))
                    Text(exercise.tip)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "F5A623").opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDone ? Color.white.opacity(0.02) : Color.white.opacity(0.05))
        )
    }
}

#Preview {
    NavigationStack {
        WorkoutView(
            gender: .male,
            selectedMuscles: [.chest, .back, .core]
        )
    }
}
