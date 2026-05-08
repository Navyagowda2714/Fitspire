//
//  PersonalizedPlanEngine.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 07/05/2026.
//


import Foundation

final class PersonalizedPlanEngine {

    func generate(from response: QuestionnaireResponse) -> GeneratedWorkoutPlan {
        let level     = response.computedFitnessLevel
        let goal      = response.primaryGoal
        let equipment = response.equipment
        let conditions = response.conditions
        let sessionMins = response.sessionLength.minutes
        let days      = response.trainingDays.rawValue
        let focus     = response.focusArea

        let sets  = sets(for: level, goal: goal)
        let reps  = reps(for: goal)
        let rest  = rest(for: goal, level: level)

        let exercises = selectExercises(
            goal: goal,
            focus: focus,
            equipment: equipment,
            conditions: conditions,
            level: level,
            sessionMinutes: sessionMins
        )

        let schedule = buildSchedule(
            exercises: exercises,
            days: days,
            focus: focus,
            goal: goal
        )

        let safetyNotes = buildSafetyNotes(
            parq: response.parqResult,
            conditions: conditions,
            level: level
        )

        let progression = buildProgressionNote(
            goal: goal,
            level: level,
            sets: sets,
            reps: reps
        )

        let timeline = timelineMonths(
            goal: goal,
            level: level,
            daysPerWeek: days
        )

        let splitType = splitDescription(
            goal: goal,
            focus: focus,
            equipment: equipment
        )

        return GeneratedWorkoutPlan(
            goal: fitnessGoal(from: goal),
            splitType: splitType,
            weeklyFrequency: days,
            workoutDays: schedule,
            progressionNote: progression,
            timelineMonths: timeline,
            safetyNotes: safetyNotes
        )
    }

    // MARK: - Volume selection

    private func sets(for level: ExperienceLevel, goal: WorkoutGoal) -> Int {
        switch (level, goal) {
        case (.beginner, _):              return 2
        case (.intermediate, .buildMuscle): return 4
        case (.intermediate, _):          return 3
        case (.advanced, _):              return 4
        }
    }

    private func reps(for goal: WorkoutGoal) -> String {
        switch goal {
        case .buildStrength:  return "5–8"
        case .buildMuscle:    return "8–12"
        case .toneUp:         return "12–15"
        case .loseFat:        return "15–20"
        case .improveHealth:  return "10–15"
        case .increaseEnergy: return "12–15"
        }
    }

    private func rest(for goal: WorkoutGoal, level: ExperienceLevel) -> Int {
        switch goal {
        case .buildStrength:  return 120
        case .buildMuscle:    return 90
        case .loseFat:        return 30
        case .toneUp:         return 45
        case .improveHealth:  return 60
        case .increaseEnergy: return 45
        }
    }

    // MARK: - Exercise selection

    private func selectExercises(
        goal: WorkoutGoal,
        focus: FocusArea,
        equipment: [HomeEquipment],
        conditions: [CommonCondition],
        level: ExperienceLevel,
        sessionMinutes: Int
    ) -> [Exercise] {

        let hasDumbbells  = equipment.contains(.dumbbells)
        let hasBands      = equipment.contains(.resistanceBands)
        let hasKettlebell = equipment.contains(.kettlebell)
        let hasPullBar    = equipment.contains(.pullUpBar)
        let hasBench      = equipment.contains(.bench)
        let hasAnkle      = equipment.contains(.ankleWeights)
        let avoid         = conditions.flatMap { $0.avoidMovements }

        let maxExercises  = sessionMinutes <= 20 ? 4 : sessionMinutes <= 30 ? 5 : 6
        let sets          = sets(for: level, goal: goal)
        let reps          = reps(for: goal)
        let rest          = rest(for: goal, level: level)

        var pool: [Exercise] = []

        // LOWER BODY
        if focus == .fullBody || focus == .lowerBody {
            if !avoid.contains("Deep squats") {
                pool.append(Exercise(
                    name: hasDumbbells ? "Dumbbell Goblet Squat"
                        : hasKettlebell ? "Kettlebell Goblet Squat"
                        : "Bodyweight Squat",
                    sets: sets, reps: reps, restSeconds: rest,
                    notes: level == .beginner ? "Keep chest up, knees over toes" : "",
                    muscleGroup: "Quads / Glutes"
                ))
            }

            if !avoid.contains("Deep lunges") {
                pool.append(Exercise(
                    name: level == .beginner ? "Reverse Lunge" : "Walking Lunges",
                    sets: sets, reps: "\(sets == 2 ? 10 : 12) each",
                    restSeconds: rest,
                    notes: "Keep front knee above ankle",
                    muscleGroup: "Glutes / Quads"
                ))
            }

            pool.append(Exercise(
                name: hasBands ? "Banded Glute Bridge" : "Glute Bridge",
                sets: sets, reps: "15–20",
                restSeconds: rest,
                notes: "Squeeze glutes at the top for 1 second",
                muscleGroup: "Glutes / Hamstrings"
            ))

            if hasAnkle || level != .beginner {
                pool.append(Exercise(
                    name: hasAnkle ? "Ankle Weight Donkey Kick" : "Donkey Kick",
                    sets: sets, reps: "12 each",
                    restSeconds: rest,
                    muscleGroup: "Glutes"
                ))
            }

            if !avoid.contains("Running") {
                pool.append(Exercise(
                    name: "Calf Raises",
                    sets: sets, reps: "20",
                    restSeconds: 30,
                    notes: "Use a step for greater range if available",
                    muscleGroup: "Calves"
                ))
            }
        }

        // UPPER BODY
        if focus == .fullBody || focus == .upperBody {
            if !avoid.contains("Push-ups on hands") {
                pool.append(Exercise(
                    name: level == .beginner ? "Knee Push-ups" : "Push-ups",
                    sets: sets, reps: reps,
                    restSeconds: rest,
                    notes: level == .beginner ? "Start on knees — progress to full push-up" : "Elbows at 45 degrees",
                    muscleGroup: "Chest / Triceps"
                ))
            }

            if !avoid.contains("Overhead press") {
                pool.append(Exercise(
                    name: hasDumbbells ? "Dumbbell Shoulder Press"
                        : hasBands ? "Band Overhead Press"
                        : "Pike Push-up",
                    sets: sets, reps: reps,
                    restSeconds: rest,
                    muscleGroup: "Shoulders"
                ))
            }

            pool.append(Exercise(
                name: hasDumbbells ? "Dumbbell Bent Over Row"
                    : hasBands ? "Resistance Band Row"
                    : hasPullBar ? "Pull-up" : "Superman Hold",
                sets: sets, reps: hasPullBar ? "5–8" : reps,
                restSeconds: rest,
                notes: "Keep back flat, squeeze shoulder blades",
                muscleGroup: "Back / Biceps"
            ))

            if !avoid.contains("Push-ups on wrists") {
                pool.append(Exercise(
                    name: hasBench ? "Tricep Dips on Bench" : "Tricep Dips on Chair",
                    sets: sets, reps: "10–12",
                    restSeconds: rest,
                    notes: "Test chair stability before starting",
                    muscleGroup: "Triceps"
                ))
            }

            if hasDumbbells || hasBands {
                pool.append(Exercise(
                    name: hasDumbbells ? "Dumbbell Bicep Curl" : "Band Bicep Curl",
                    sets: sets, reps: reps,
                    restSeconds: rest,
                    muscleGroup: "Biceps"
                ))
            }
        }

        // CORE
        if focus == .fullBody || focus == .core {
            if !avoid.contains("Sit-ups") && !avoid.contains("Crunches") {
                pool.append(Exercise(
                    name: avoid.contains("Lying flat on back") ? "Standing Side Crunch"
                        : "Bicycle Crunches",
                    sets: sets, reps: "15 each",
                    restSeconds: 30,
                    muscleGroup: "Abs / Obliques"
                ))
            }

            if !avoid.contains("Lying flat on back") {
                pool.append(Exercise(
                    name: "Plank",
                    sets: sets, reps: level == .beginner ? "20–30 sec" : "40–60 sec",
                    restSeconds: 30,
                    notes: "Straight line from head to heel — breathe",
                    muscleGroup: "Core"
                ))
            }

            pool.append(Exercise(
                name: "Dead Bug",
                sets: sets, reps: "8 each",
                restSeconds: 30,
                notes: "Lower back pressed to floor throughout",
                muscleGroup: "Deep Core"
            ))
        }

        // CARDIO for fat loss or endurance
        if goal == .loseFat || goal == .increaseEnergy {
            if !avoid.contains("High impact jumps") {
                pool.append(Exercise(
                    name: equipment.contains(.jumpRope) ? "Jump Rope" : "Jumping Jacks",
                    sets: 1, reps: "3 min",
                    restSeconds: 60,
                    notes: "Use as warm-up or circuit finisher",
                    muscleGroup: "Cardio"
                ))
            }

            if !avoid.contains("High intensity intervals") {
                pool.append(Exercise(
                    name: level == .beginner ? "Step Touch" : "Mountain Climbers",
                    sets: sets, reps: level == .beginner ? "30 sec" : "20 each",
                    restSeconds: 30,
                    muscleGroup: "Cardio / Core"
                ))
            }
        }

        return Array(pool.prefix(maxExercises))
    }

    // MARK: - Schedule builder

    private func buildSchedule(
        exercises: [Exercise],
        days: Int,
        focus: FocusArea,
        goal: WorkoutGoal
    ) -> [WorkoutDay] {

        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday",
                        "Friday", "Saturday", "Sunday"]

        var schedule: [WorkoutDay] = []
        var workoutDayIndices: [Int]

        switch days {
        case 3: workoutDayIndices = [0, 2, 4]
        case 4: workoutDayIndices = [0, 1, 3, 4]
        default: workoutDayIndices = [0, 1, 2, 4, 5]
        }

        for (index, dayName) in dayNames.enumerated() {
            if workoutDayIndices.contains(index) {
                schedule.append(WorkoutDay(
                    dayName: dayName,
                    focusArea: focus.rawValue,
                    exercises: exercises,
                    estimatedMinutes: estimateMinutes(exercises: exercises)
                ))
            } else {
                schedule.append(WorkoutDay(
                    dayName: dayName,
                    focusArea: "Rest / light walk",
                    isRestDay: true
                ))
            }
        }
        return schedule
    }

    private func estimateMinutes(exercises: [Exercise]) -> Int {
        return exercises.count * 8
    }

    // MARK: - Notes

    private func buildSafetyNotes(
        parq: PARQResult,
        conditions: [CommonCondition],
        level: ExperienceLevel
    ) -> [String] {
        var notes: [String] = []

        if parq.requiresMedicalClearance {
            notes.append("⚠️ Please consult your doctor before starting. Your PAR-Q responses indicate medical clearance is recommended.")
        }

        if conditions.contains(.backPain) {
            notes.append("Back pain noted: avoid loading the spine. Focus on core strengthening and gentle movement.")
        }

        if conditions.contains(.kneePain) {
            notes.append("Knee pain noted: keep all squats shallow, avoid impact exercises until pain-free.")
        }

        if conditions.contains(.pregnancy) {
            notes.append("Pregnancy: avoid lying flat on back after 16 weeks, no high impact. Always consult your midwife.")
        }

        if level == .beginner {
            notes.append("As a beginner, focus on learning movement patterns before adding speed or resistance.")
            notes.append("Stop immediately if you feel sharp pain. Mild muscle fatigue is normal — sharp pain is not.")
        }

        notes.append("Warm up for 5 minutes with light movement before every session.")
        notes.append("Stay hydrated — drink water before, during, and after each workout.")

        return notes
    }

    private func buildProgressionNote(
        goal: WorkoutGoal,
        level: ExperienceLevel,
        sets: Int,
        reps: String
    ) -> String {
        switch goal {
        case .buildStrength:
            return "Add 1–2 reps per exercise every week. When you can complete all sets comfortably, increase resistance or try a harder variation."
        case .buildMuscle:
            return "Increase reps by 1–2 each week until you reach the top of your rep range, then add a set. Rest and sleep are as important as the workout."
        case .loseFat:
            return "Reduce rest periods by 5 seconds each week. Add a cardio finisher (2 min jump rope or 20 burpees) to each session after week 2."
        case .toneUp:
            return "Focus on form first — quality over quantity. Add reps weekly. After 4 weeks, add a third set to your main exercises."
        case .improveHealth:
            return "Consistency is your only metric. Show up 3 times a week for 4 weeks — that alone will change how you feel."
        case .increaseEnergy:
            return "Short daily movement beats one long session. Add 5 minutes of walking on rest days for compounding energy benefits."
        }
    }

    private func timelineMonths(
        goal: WorkoutGoal,
        level: ExperienceLevel,
        daysPerWeek: Int
    ) -> Int {
        let base: Int
        switch goal {
        case .buildStrength:  base = 4
        case .buildMuscle:    base = 5
        case .loseFat:        base = 3
        case .toneUp:         base = 3
        case .improveHealth:  base = 2
        case .increaseEnergy: base = 2
        }
        let dayBonus = daysPerWeek >= 4 ? -1 : 0
        let levelBonus = level == .beginner ? 1 : 0
        return max(1, base + dayBonus + levelBonus)
    }

    private func splitDescription(
        goal: WorkoutGoal,
        focus: FocusArea,
        equipment: [HomeEquipment]
    ) -> String {
        let equipSuffix = equipment.contains(.noEquipment)
            ? "bodyweight only"
            : "home equipment"
        return "\(focus.rawValue) · \(goal.rawValue) · \(equipSuffix)"
    }

    private func fitnessGoal(from goal: WorkoutGoal) -> FitnessGoal {
        switch goal {
        case .buildMuscle, .buildStrength: return .muscleBuilding
        case .loseFat:                     return .leanBody
        case .toneUp:                      return .stayingLean
        case .improveHealth:               return .stayingActive
        case .increaseEnergy:              return .enduranceFitness
        }
    }
}
