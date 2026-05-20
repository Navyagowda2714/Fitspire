//
//  WorkoutRecommendationEngine.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation

final class WorkoutRecommendationEngine {

    func generate(
        goal: FitnessGoal,
        experience: String,
        injuries: [String] = [],
        postureScore: Double = 80
    ) -> GeneratedWorkoutPlan {

        let level = ExperienceLevel(rawValue: experience) ?? .beginner

        switch goal {
        case .muscleBuilding:   return muscleBuildingPlan(level: level, injuries: injuries)
        case .leanBody:         return leanBodyPlan(level: level, injuries: injuries)
        case .bulking:          return bulkingPlan(level: level, injuries: injuries)
        case .tournamentPrep:   return tournamentPlan(level: level, injuries: injuries)
        case .enduranceFitness: return endurancePlan(level: level, injuries: injuries)
        case .stayingActive:    return stayingActivePlan(level: level, injuries: injuries)
        case .stayingLean:      return stayingLeanPlan(level: level, injuries: injuries)
        }
    }

    // MARK: - Muscle Building

    private func muscleBuildingPlan(
        level: ExperienceLevel,
        injuries: [String]
    ) -> GeneratedWorkoutPlan {
        let sets  = level == .beginner ? 3 : 4
        let reps  = "8–12"
        let rest  = level == .beginner ? 90 : 120

        let days: [WorkoutDay] = [
            WorkoutDay(
                dayName: "Monday",
                focusArea: "Push — Chest, Shoulders, Triceps",
                exercises: [
                    Exercise(name: "Barbell Bench Press",       sets: sets, reps: reps, restSeconds: rest, muscleGroup: "Chest"),
                    Exercise(name: "Incline Dumbbell Press",    sets: sets, reps: reps, restSeconds: rest, muscleGroup: "Chest"),
                    Exercise(name: "Overhead Press",            sets: sets, reps: reps, restSeconds: rest, muscleGroup: "Shoulders"),
                    Exercise(name: "Lateral Raises",            sets: 3,    reps: "12–15", restSeconds: 60, muscleGroup: "Shoulders"),
                    Exercise(name: "Tricep Pushdowns",          sets: 3,    reps: "12–15", restSeconds: 60, muscleGroup: "Triceps")
                ],
                estimatedMinutes: 60
            ),
            WorkoutDay(
                dayName: "Tuesday",
                focusArea: "Pull — Back, Biceps",
                exercises: [
                    Exercise(name: "Deadlift",                  sets: sets, reps: "5–8",   restSeconds: 180, muscleGroup: "Back"),
                    Exercise(name: "Bent Over Row",             sets: sets, reps: reps,    restSeconds: rest, muscleGroup: "Back"),
                    Exercise(name: "Pull-ups",                  sets: 3,    reps: "6–10",  restSeconds: rest, muscleGroup: "Back"),
                    Exercise(name: "Face Pulls",                sets: 3,    reps: "15–20", restSeconds: 60,   muscleGroup: "Rear Delts"),
                    Exercise(name: "Barbell Bicep Curls",       sets: 3,    reps: reps,    restSeconds: 60,   muscleGroup: "Biceps")
                ],
                estimatedMinutes: 60
            ),
            WorkoutDay(
                dayName: "Wednesday",
                focusArea: "Rest / Active recovery",
                isRestDay: true,
            ),
            WorkoutDay(
                dayName: "Thursday",
                focusArea: "Legs — Quads, Glutes, Hamstrings",
                exercises: [
                    Exercise(name: "Barbell Squat",             sets: sets, reps: reps,    restSeconds: 180, muscleGroup: "Quads"),
                    Exercise(name: "Romanian Deadlift",         sets: sets, reps: reps,    restSeconds: rest, muscleGroup: "Hamstrings"),
                    Exercise(name: "Leg Press",                 sets: 3,    reps: "10–15", restSeconds: rest, muscleGroup: "Quads"),
                    Exercise(name: "Walking Lunges",            sets: 3,    reps: "12 each", restSeconds: 90, muscleGroup: "Glutes"),
                    Exercise(name: "Calf Raises",               sets: 4,    reps: "15–20", restSeconds: 60,  muscleGroup: "Calves")
                ],
                estimatedMinutes: 65
            ),
            WorkoutDay(
                dayName: "Friday",
                focusArea: "Upper — Compound focus",
                exercises: [
                    Exercise(name: "Incline Bench Press",       sets: sets, reps: reps,    restSeconds: rest, muscleGroup: "Chest"),
                    Exercise(name: "Cable Rows",                sets: sets, reps: reps,    restSeconds: rest, muscleGroup: "Back"),
                    Exercise(name: "Dumbbell Shoulder Press",   sets: sets, reps: reps,    restSeconds: rest, muscleGroup: "Shoulders"),
                    Exercise(name: "Hammer Curls",              sets: 3,    reps: "10–12", restSeconds: 60,   muscleGroup: "Biceps"),
                    Exercise(name: "Skull Crushers",            sets: 3,    reps: "10–12", restSeconds: 60,   muscleGroup: "Triceps")
                ],
                estimatedMinutes: 60
            ),
            WorkoutDay(
                dayName: "Saturday",
                focusArea: "Rest / Active recovery",
                isRestDay: true,
            
            ),
            WorkoutDay(
                dayName: "Sunday",
                focusArea: "Rest",
                isRestDay: true,
                
            )
        ]

        return GeneratedWorkoutPlan(
            goal: .muscleBuilding,
            splitType: "Push / Pull / Legs",
            weeklyFrequency: 4,
            workoutDays: days,
            progressionNote: "Add 2.5kg every 2–3 weeks on compound lifts when all sets are completed with good form.",
            timelineMonths: level == .beginner ? 6 : 4,
            safetyNotes: [
                "Warm up with 5–10 minutes of light cardio before each session.",
                "Focus on form over weight, especially in the first 4 weeks.",
                "Sleep 7–9 hours per night for optimal muscle recovery."
            ]
        )
    }

    // MARK: - Lean Body

    private func leanBodyPlan(
        level: ExperienceLevel,
        injuries: [String]
    ) -> GeneratedWorkoutPlan {
        let sets = level == .beginner ? 3 : 4
        let rest = 60

        let days: [WorkoutDay] = [
            WorkoutDay(
                dayName: "Monday",
                focusArea: "Full body strength A",
                exercises: [
                    Exercise(name: "Goblet Squat",              sets: sets, reps: "12–15", restSeconds: rest, muscleGroup: "Legs"),
                    Exercise(name: "Push-ups",                  sets: sets, reps: "10–15", restSeconds: rest, muscleGroup: "Chest"),
                    Exercise(name: "Dumbbell Row",              sets: sets, reps: "12 each", restSeconds: rest, muscleGroup: "Back"),
                    Exercise(name: "Plank",                     sets: 3,    reps: "30–60s", restSeconds: 45,  muscleGroup: "Core"),
                    Exercise(name: "Jump Rope",                 sets: 1,    reps: "10 min", restSeconds: 0,   muscleGroup: "Cardio")
                ],
                estimatedMinutes: 45
            ),
            WorkoutDay(
                dayName: "Tuesday",
                focusArea: "Cardio + Core",
                exercises: [
                    Exercise(name: "Treadmill / Outdoor Run",   sets: 1,    reps: "25 min", restSeconds: 0,  muscleGroup: "Cardio"),
                    Exercise(name: "Mountain Climbers",         sets: 3,    reps: "20 each", restSeconds: 45, muscleGroup: "Core"),
                    Exercise(name: "Bicycle Crunches",          sets: 3,    reps: "20 each", restSeconds: 45, muscleGroup: "Core")
                ],
                estimatedMinutes: 40
            ),
            WorkoutDay(
                dayName: "Wednesday",
                focusArea: "Rest / Mobility",
                isRestDay: true,
            ),
            WorkoutDay(
                dayName: "Thursday",
                focusArea: "Full body strength B",
                exercises: [
                    Exercise(name: "Dumbbell Lunges",           sets: sets, reps: "12 each", restSeconds: rest, muscleGroup: "Legs"),
                    Exercise(name: "Incline Push-ups",          sets: sets, reps: "12–15",  restSeconds: rest, muscleGroup: "Chest"),
                    Exercise(name: "Lat Pulldowns",             sets: sets, reps: "12–15",  restSeconds: rest, muscleGroup: "Back"),
                    Exercise(name: "Romanian Deadlift",         sets: sets, reps: "12",     restSeconds: rest, muscleGroup: "Hamstrings"),
                    Exercise(name: "Lateral Raises",            sets: 3,    reps: "15",     restSeconds: 45,   muscleGroup: "Shoulders")
                ],
                estimatedMinutes: 50
            ),
            WorkoutDay(
                dayName: "Friday",
                focusArea: "HIIT + Abs",
                exercises: [
                    Exercise(name: "HIIT Circuit",              sets: 4,    reps: "40s on 20s off", restSeconds: 60, muscleGroup: "Full body"),
                    Exercise(name: "Plank Variations",          sets: 3,    reps: "45s each",       restSeconds: 45, muscleGroup: "Core")
                ],
                estimatedMinutes: 35
            ),
            WorkoutDay(
                dayName: "Saturday",
                focusArea: "Active recovery / Walk",
                isRestDay: true,
            ),
            WorkoutDay(
                dayName: "Sunday",
                focusArea: "Rest",
                isRestDay: true,
            )
        ]

        return GeneratedWorkoutPlan(
            goal: .leanBody,
            splitType: "Full body + Cardio",
            weeklyFrequency: 4,
            workoutDays: days,
            progressionNote: "Increase weights by 1–2kg every 2 weeks. Add 5 minutes to cardio sessions monthly.",
            timelineMonths: 3,
            safetyNotes: [
                "Maintain a moderate calorie deficit of 300–500 kcal per day.",
                "Prioritise protein intake at 1.6–2g per kg of body weight.",
                "Do not skip rest days — recovery is essential for fat loss."
            ]
        )
    }

    // MARK: - Bulking

    private func bulkingPlan(
        level: ExperienceLevel,
        injuries: [String]
    ) -> GeneratedWorkoutPlan {
        let sets = level == .beginner ? 4 : 5
        let rest = 180

        let days: [WorkoutDay] = [
            WorkoutDay(
                dayName: "Monday",
                focusArea: "Heavy Chest + Triceps",
                exercises: [
                    Exercise(name: "Barbell Bench Press",       sets: sets, reps: "4–6",  restSeconds: rest,  muscleGroup: "Chest"),
                    Exercise(name: "Weighted Dips",             sets: sets, reps: "6–8",  restSeconds: rest,  muscleGroup: "Chest"),
                    Exercise(name: "Incline Dumbbell Press",    sets: 4,    reps: "8–10", restSeconds: 120,   muscleGroup: "Chest"),
                    Exercise(name: "Close Grip Bench",          sets: 4,    reps: "6–8",  restSeconds: 120,   muscleGroup: "Triceps")
                ],
                estimatedMinutes: 70
            ),
            WorkoutDay(
                dayName: "Tuesday",
                focusArea: "Heavy Back + Biceps",
                exercises: [
                    Exercise(name: "Deadlift",                  sets: sets, reps: "4–6",  restSeconds: rest,  muscleGroup: "Back"),
                    Exercise(name: "Weighted Pull-ups",         sets: 4,    reps: "5–8",  restSeconds: rest,  muscleGroup: "Back"),
                    Exercise(name: "Barbell Row",               sets: 4,    reps: "6–8",  restSeconds: 120,   muscleGroup: "Back"),
                    Exercise(name: "Barbell Curls",             sets: 4,    reps: "6–8",  restSeconds: 90,    muscleGroup: "Biceps")
                ],
                estimatedMinutes: 70
            ),
            WorkoutDay(
                dayName: "Wednesday",
                focusArea: "Rest",
                isRestDay: true
            ),
            WorkoutDay(
                dayName: "Thursday",
                focusArea: "Heavy Legs",
                exercises: [
                    Exercise(name: "Barbell Squat",             sets: sets, reps: "4–6",  restSeconds: rest,  muscleGroup: "Quads"),
                    Exercise(name: "Leg Press",                 sets: 4,    reps: "8–10", restSeconds: 120,   muscleGroup: "Quads"),
                    Exercise(name: "Romanian Deadlift",         sets: 4,    reps: "6–8",  restSeconds: 120,   muscleGroup: "Hamstrings"),
                    Exercise(name: "Calf Raises",               sets: 5,    reps: "10–15", restSeconds: 60,   muscleGroup: "Calves")
                ],
                estimatedMinutes: 70
            ),
            WorkoutDay(
                dayName: "Friday",
                focusArea: "Shoulders + Arms",
                exercises: [
                    Exercise(name: "Overhead Press",            sets: sets, reps: "4–6",  restSeconds: rest,  muscleGroup: "Shoulders"),
                    Exercise(name: "Arnold Press",              sets: 4,    reps: "8–10", restSeconds: 90,    muscleGroup: "Shoulders"),
                    Exercise(name: "Incline Dumbbell Curls",    sets: 3,    reps: "8–10", restSeconds: 90,    muscleGroup: "Biceps"),
                    Exercise(name: "Overhead Tricep Extension", sets: 3,    reps: "8–10", restSeconds: 90,    muscleGroup: "Triceps")
                ],
                estimatedMinutes: 65
            ),
            WorkoutDay(dayName: "Saturday", focusArea: "Rest", isRestDay: true),
            WorkoutDay(dayName: "Sunday",   focusArea: "Rest", isRestDay: true)
        ]

        return GeneratedWorkoutPlan(
            goal: .bulking,
            splitType: "Heavy compound split",
            weeklyFrequency: 5,
            workoutDays: days,
            progressionNote: "Progressive overload every week. Add 2.5–5kg on big lifts each session when reps are completed cleanly.",
            timelineMonths: 6,
            safetyNotes: [
                "Eat in a 300–500 kcal surplus daily.",
                "Prioritise compound lifts — squat, bench, deadlift, overhead press.",
                "Track your lifts every session to ensure progressive overload."
            ]
        )
    }

    // MARK: - Tournament Prep

    private func tournamentPlan(
        level: ExperienceLevel,
        injuries: [String]
    ) -> GeneratedWorkoutPlan {
        let days: [WorkoutDay] = [
            WorkoutDay(
                dayName: "Monday",
                focusArea: "Strength + Power",
                exercises: [
                    Exercise(name: "Power Clean",               sets: 5, reps: "3",      restSeconds: 180, muscleGroup: "Full body"),
                    Exercise(name: "Back Squat",                sets: 4, reps: "4–6",   restSeconds: 180, muscleGroup: "Legs"),
                    Exercise(name: "Bench Press",               sets: 4, reps: "4–6",   restSeconds: 180, muscleGroup: "Chest")
                ],
                estimatedMinutes: 60
            ),
            WorkoutDay(
                dayName: "Tuesday",
                focusArea: "Conditioning",
                exercises: [
                    Exercise(name: "Interval Sprints",          sets: 8, reps: "30s on 90s off", restSeconds: 0, muscleGroup: "Cardio"),
                    Exercise(name: "Agility Ladder Drills",     sets: 4, reps: "2 min", restSeconds: 60,  muscleGroup: "Agility")
                ],
                estimatedMinutes: 45
            ),
            WorkoutDay(dayName: "Wednesday", focusArea: "Rest / Mobility", isRestDay: true),
            WorkoutDay(
                dayName: "Thursday",
                focusArea: "Strength + Mobility",
                exercises: [
                    Exercise(name: "Deadlift",                  sets: 4, reps: "4–6",   restSeconds: 180, muscleGroup: "Back"),
                    Exercise(name: "Bulgarian Split Squat",     sets: 3, reps: "8 each", restSeconds: 90, muscleGroup: "Legs"),
                    Exercise(name: "Mobility Circuit",          sets: 1, reps: "20 min", restSeconds: 0,  muscleGroup: "Mobility")
                ],
                estimatedMinutes: 60
            ),
            WorkoutDay(
                dayName: "Friday",
                focusArea: "Event-specific training",
                exercises: [
                    Exercise(name: "Sport-specific drills",     sets: 1, reps: "45 min", restSeconds: 0,  muscleGroup: "Sport"),
                    Exercise(name: "Core stability circuit",    sets: 3, reps: "15 each", restSeconds: 45, muscleGroup: "Core")
                ],
                estimatedMinutes: 60
            ),
            WorkoutDay(dayName: "Saturday", focusArea: "Light recovery", isRestDay: true),
            WorkoutDay(dayName: "Sunday",   focusArea: "Rest",            isRestDay: true)
        ]

        return GeneratedWorkoutPlan(
            goal: .tournamentPrep,
            splitType: "Strength + Conditioning",
            weeklyFrequency: 5,
            workoutDays: days,
            progressionNote: "Adjust intensity based on competition calendar. Taper 1–2 weeks before event.",
            timelineMonths: 3,
            safetyNotes: [
                "Injury prevention is the priority — never train through pain.",
                "Include at least 10 minutes of mobility work every session.",
                "Taper training volume 2 weeks before competition."
            ]
        )
    }

    // MARK: - Endurance

    private func endurancePlan(
        level: ExperienceLevel,
        injuries: [String]
    ) -> GeneratedWorkoutPlan {
        let days: [WorkoutDay] = [
            WorkoutDay(
                dayName: "Monday",
                focusArea: "Zone 2 cardio",
                exercises: [
                    Exercise(name: "Easy Run / Cycle",          sets: 1, reps: "30–45 min", restSeconds: 0, muscleGroup: "Cardio")
                ],
                estimatedMinutes: 45
            ),
            WorkoutDay(
                dayName: "Tuesday",
                focusArea: "Strength support",
                exercises: [
                    Exercise(name: "Goblet Squats",             sets: 3, reps: "15",     restSeconds: 60, muscleGroup: "Legs"),
                    Exercise(name: "Single Leg Deadlift",       sets: 3, reps: "10 each", restSeconds: 60, muscleGroup: "Hamstrings"),
                    Exercise(name: "Push-ups",                  sets: 3, reps: "15",     restSeconds: 60, muscleGroup: "Chest"),
                    Exercise(name: "Plank",                     sets: 3, reps: "45s",    restSeconds: 45, muscleGroup: "Core")
                ],
                estimatedMinutes: 40
            ),
            WorkoutDay(dayName: "Wednesday", focusArea: "Rest / Mobility", isRestDay: true),
            WorkoutDay(
                dayName: "Thursday",
                focusArea: "Tempo intervals",
                exercises: [
                    Exercise(name: "Tempo Run / Row",           sets: 4, reps: "5 min on 2 min off", restSeconds: 0, muscleGroup: "Cardio")
                ],
                estimatedMinutes: 40
            ),
            WorkoutDay(
                dayName: "Friday",
                focusArea: "Strength + Core",
                exercises: [
                    Exercise(name: "Step-ups",                  sets: 3, reps: "12 each", restSeconds: 60, muscleGroup: "Legs"),
                    Exercise(name: "Resistance Band Rows",      sets: 3, reps: "15",      restSeconds: 60, muscleGroup: "Back"),
                    Exercise(name: "Dead Bugs",                 sets: 3, reps: "10 each", restSeconds: 45, muscleGroup: "Core")
                ],
                estimatedMinutes: 40
            ),
            WorkoutDay(
                dayName: "Saturday",
                focusArea: "Long slow distance",
                exercises: [
                    Exercise(name: "Long run / cycle / swim",   sets: 1, reps: "60–90 min", restSeconds: 0, muscleGroup: "Cardio")
                ],
                estimatedMinutes: 90
            ),
            WorkoutDay(dayName: "Sunday", focusArea: "Rest", isRestDay: true)
        ]

        return GeneratedWorkoutPlan(
            goal: .enduranceFitness,
            splitType: "Zone 2 + Intervals + Strength",
            weeklyFrequency: 5,
            workoutDays: days,
            progressionNote: "Increase long run by 10% per week. Add one interval session per month as fitness improves.",
            timelineMonths: 4,
            safetyNotes: [
                "Never increase weekly mileage by more than 10%.",
                "Include strength work to prevent common overuse injuries.",
                "Fuel well before sessions longer than 60 minutes."
            ]
        )
    }

    // MARK: - Staying Active

    private func stayingActivePlan(
        level: ExperienceLevel,
        injuries: [String]
    ) -> GeneratedWorkoutPlan {
        let days: [WorkoutDay] = [
            WorkoutDay(
                dayName: "Monday",
                focusArea: "Full body workout",
                exercises: [
                    Exercise(name: "Bodyweight Squats",         sets: 3, reps: "15",     restSeconds: 60, muscleGroup: "Legs"),
                    Exercise(name: "Push-ups",                  sets: 3, reps: "10–12",  restSeconds: 60, muscleGroup: "Chest"),
                    Exercise(name: "Resistance Band Rows",      sets: 3, reps: "12",     restSeconds: 60, muscleGroup: "Back"),
                    Exercise(name: "Plank",                     sets: 2, reps: "30s",    restSeconds: 45, muscleGroup: "Core")
                ],
                estimatedMinutes: 35
            ),
            WorkoutDay(dayName: "Tuesday",   focusArea: "Walk 30 min", isRestDay: true),
            WorkoutDay(
                dayName: "Wednesday",
                focusArea: "Light cardio + Mobility",
                exercises: [
                    Exercise(name: "Brisk Walk / Cycle",        sets: 1, reps: "30 min", restSeconds: 0, muscleGroup: "Cardio"),
                    Exercise(name: "Stretching routine",        sets: 1, reps: "10 min", restSeconds: 0, muscleGroup: "Mobility")
                ],
                estimatedMinutes: 40
            ),
            WorkoutDay(dayName: "Thursday",  focusArea: "Rest",        isRestDay: true),
            WorkoutDay(
                dayName: "Friday",
                focusArea: "Full body workout B",
                exercises: [
                    Exercise(name: "Glute Bridges",             sets: 3, reps: "15",     restSeconds: 60, muscleGroup: "Glutes"),
                    Exercise(name: "Dumbbell Rows",             sets: 3, reps: "12 each", restSeconds: 60, muscleGroup: "Back"),
                    Exercise(name: "Shoulder Press",            sets: 3, reps: "12",     restSeconds: 60, muscleGroup: "Shoulders"),
                    Exercise(name: "Bird Dog",                  sets: 2, reps: "10 each", restSeconds: 45, muscleGroup: "Core")
                ],
                estimatedMinutes: 35
            ),
            WorkoutDay(dayName: "Saturday",  focusArea: "Active rest / Fun activity", isRestDay: true),
            WorkoutDay(dayName: "Sunday",    focusArea: "Rest",                        isRestDay: true)
        ]

        return GeneratedWorkoutPlan(
            goal: .stayingActive,
            splitType: "Full body 2x per week",
            weeklyFrequency: 3,
            workoutDays: days,
            progressionNote: "Focus on consistency over intensity. Add one rep or a small weight increase every 2–3 weeks.",
            timelineMonths: 2,
            safetyNotes: [
                "Listen to your body — rest when you feel tired.",
                "Any movement is better than no movement.",
                "Stay hydrated and get 7–8 hours of sleep."
            ]
        )
    }

    // MARK: - Staying Lean

    private func stayingLeanPlan(
        level: ExperienceLevel,
        injuries: [String]
    ) -> GeneratedWorkoutPlan {
        let sets = 3
        let rest = 75

        let days: [WorkoutDay] = [
            WorkoutDay(
                dayName: "Monday",
                focusArea: "Upper body strength",
                exercises: [
                    Exercise(name: "Bench Press",               sets: sets, reps: "10–12", restSeconds: rest, muscleGroup: "Chest"),
                    Exercise(name: "Cable Rows",                sets: sets, reps: "10–12", restSeconds: rest, muscleGroup: "Back"),
                    Exercise(name: "Shoulder Press",            sets: sets, reps: "10–12", restSeconds: rest, muscleGroup: "Shoulders"),
                    Exercise(name: "Tricep Dips",               sets: sets, reps: "12",    restSeconds: 60,   muscleGroup: "Triceps")
                ],
                estimatedMinutes: 50
            ),
            WorkoutDay(
                dayName: "Tuesday",
                focusArea: "Cardio maintenance",
                exercises: [
                    Exercise(name: "Moderate run / Cycle",      sets: 1, reps: "30 min",  restSeconds: 0,   muscleGroup: "Cardio")
                ],
                estimatedMinutes: 35
            ),
            WorkoutDay(dayName: "Wednesday", focusArea: "Rest / Mobility", isRestDay: true),
            WorkoutDay(
                dayName: "Thursday",
                focusArea: "Lower body strength",
                exercises: [
                    Exercise(name: "Barbell Squat",             sets: sets, reps: "10–12", restSeconds: rest, muscleGroup: "Quads"),
                    Exercise(name: "Romanian Deadlift",         sets: sets, reps: "10–12", restSeconds: rest, muscleGroup: "Hamstrings"),
                    Exercise(name: "Leg Curl",                  sets: sets, reps: "12–15", restSeconds: 60,   muscleGroup: "Hamstrings"),
                    Exercise(name: "Calf Raises",               sets: 3,    reps: "15–20", restSeconds: 45,   muscleGroup: "Calves")
                ],
                estimatedMinutes: 50
            ),
            WorkoutDay(
                dayName: "Friday",
                focusArea: "Full body circuit",
                exercises: [
                    Exercise(name: "Circuit training",          sets: 4, reps: "12 each exercise", restSeconds: 45, muscleGroup: "Full body")
                ],
                estimatedMinutes: 40
            ),
            WorkoutDay(dayName: "Saturday", focusArea: "Light cardio / Walk", isRestDay: true),
            WorkoutDay(dayName: "Sunday",   focusArea: "Rest",                  isRestDay: true)
        ]

        return GeneratedWorkoutPlan(
            goal: .stayingLean,
            splitType: "Upper / Lower + Cardio",
            weeklyFrequency: 4,
            workoutDays: days,
            progressionNote: "Maintain current weight levels with small increases every 3–4 weeks. Prioritise consistency.",
            timelineMonths: 3,
            safetyNotes: [
                "Eat at maintenance calories — not a deficit.",
                "Track weekly body measurements rather than daily weight.",
                "Keep cardio consistent at 2–3 sessions per week."
            ]
        )
    }
}
