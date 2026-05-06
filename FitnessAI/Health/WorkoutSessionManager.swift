//
//  WorkoutSessionManager.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation
import HealthKit
import Combine

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

        guard let calType = HKQuantityType.quantityType(
            forIdentifier: .activeEnergyBurned
        ) else { return false }

        let calQuantity = HKQuantity(
            unit: .kilocalorie(),
            doubleValue: calories
        )

        let calSample = HKQuantitySample(
            type: calType,
            quantity: calQuantity,
            start: startDate,
            end: endDate
        )

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: .local()
        )

        do {
            try await builder.beginCollection(at: startDate)
            try await builder.addSamples([calSample])
            try await builder.endCollection(at: endDate)
            let workout = try await builder.finishWorkout()
            lastSavedWorkout = workout
            return true
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
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
            return .traditionalStrengthTraining
        }
    }
}
