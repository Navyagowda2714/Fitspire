//
//  WorkoutSessionManager.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation
import HealthKit

@MainActor
final class WorkoutSessionManager: ObservableObject {
    private let store = HKHealthStore()

    @Published var isSaving: Bool = false
    @Published var lastSavedWorkout: HKWorkout?
    @Published var errorMessage: String?

    // MARK: - Save completed workout

    func saveWorkout(
        activityType: HKWorkoutActivityType = .traditionalStrengthTraining,
        startDate: Date,
        endDate: Date,
        calories: Double,
        formScore: Int
    ) async -> Bool {
        isSaving = true
        defer { isSaving = false }

        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit not available."
            return false
        }

        let energyBurned = HKQuantity(
            unit: .kilocalorie(),
            doubleValue: calories
        )

        let workout = HKWorkout(
            activityType: activityType,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: energyBurned,
            totalDistance: nil,
            metadata: [
                "formScore": formScore,
                "source": "FitnessAI"
            ]
        )

        do {
            try await store.save(workout)
            lastSavedWorkout = workout
            return true
        } catch {
            errorMessage = "Failed to save workout: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Activity type from exercise

    func activityType(
        for exercise: ExerciseType
    ) -> HKWorkoutActivityType {
        switch exercise {
        case .squat, .deadlift, .shoulderPress, .pushUp:
            return .traditionalStrengthTraining
        case .plank:
            return .coreTraining
        case .general:
            return .functionalStrength
        }
    }
}
