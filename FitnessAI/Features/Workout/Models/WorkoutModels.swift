//
//  WorkoutModels.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//


import Foundation

struct WorkoutDay: Identifiable {
    let id = UUID()
    let dayName: String
    let focusArea: String
    let exercises: [Exercise]
    let estimatedMinutes: Int
    let isRestDay: Bool

    init(
        dayName: String,
        focusArea: String,
        exercises: [Exercise] = [],
        estimatedMinutes: Int = 0,
        isRestDay: Bool = false
    ) {
        self.dayName           = dayName
        self.focusArea         = focusArea
        self.exercises         = exercises
        self.estimatedMinutes  = estimatedMinutes
        self.isRestDay         = isRestDay
    }
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: String
    let restSeconds: Int
    let notes: String
    let muscleGroup: String

    init(
        name: String,
        sets: Int,
        reps: String,
        restSeconds: Int,
        notes: String = "",
        muscleGroup: String = ""
    ) {
        self.name         = name
        self.sets         = sets
        self.reps         = reps
        self.restSeconds  = restSeconds
        self.notes        = notes
        self.muscleGroup  = muscleGroup
    }
}

struct GeneratedWorkoutPlan: Identifiable {
    let id = UUID()
    let goal: FitnessGoal
    let splitType: String
    let weeklyFrequency: Int
    let workoutDays: [WorkoutDay]
    let progressionNote: String
    let timelineMonths: Int
    let safetyNotes: [String]
    let createdAt: Date

    init(
        goal: FitnessGoal,
        splitType: String,
        weeklyFrequency: Int,
        workoutDays: [WorkoutDay],
        progressionNote: String,
        timelineMonths: Int,
        safetyNotes: [String] = []
    ) {
        self.goal              = goal
        self.splitType         = splitType
        self.weeklyFrequency   = weeklyFrequency
        self.workoutDays       = workoutDays
        self.progressionNote   = progressionNote
        self.timelineMonths    = timelineMonths
        self.safetyNotes       = safetyNotes
        self.createdAt         = Date()
    }
}
