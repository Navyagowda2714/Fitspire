//
//  HealthKitManager.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    @Published var isAuthorized: Bool = false
    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var steps: Int = 0
    @Published var errorMessage: String?

    private var heartRateQuery: HKQuery?

    // Types to read
    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let hr    = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let cal   = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(cal) }
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        types.insert(HKObjectType.workoutType())
        return types
    }()

    private let writeTypes: Set<HKSampleType> = {
        var types = Set<HKSampleType>()
        if let cal = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(cal) }
        types.insert(HKObjectType.workoutType())
        return types
    }()

    private init() {}

    // MARK: - Permissions

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device."
            return false
        }

        do {
            try await store.requestAuthorization(
                toShare: writeTypes,
                read: readTypes
            )
            isAuthorized = true
            return true
        } catch {
            errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
            return false
        }
    }

    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let workoutType = HKObjectType.workoutType()
        let status = store.authorizationStatus(for: workoutType)
        isAuthorized = status == .sharingAuthorized
    }

    // MARK: - Read steps

    func fetchTodaySteps() async -> Int {
        guard let stepType = HKQuantityType.quantityType(
            forIdentifier: .stepCount
        ) else { return 0 }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let count = result?.sumQuantity()?.doubleValue(
                    for: HKUnit.count()
                ) ?? 0
                continuation.resume(returning: Int(count))
            }
            store.execute(query)
        }
    }

    // MARK: - Read active calories today

    func fetchTodayCalories() async -> Double {
        guard let calType = HKQuantityType.quantityType(
            forIdentifier: .activeEnergyBurned
        ) else { return 0 }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: calType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let cal = result?.sumQuantity()?.doubleValue(
                    for: HKUnit.kilocalorie()
                ) ?? 0
                continuation.resume(returning: cal)
            }
            store.execute(query)
        }
    }

    // MARK: - Live heart rate

    func startHeartRateMonitoring() {
        guard let hrType = HKQuantityType.quantityType(
            forIdentifier: .heartRate
        ) else { return }

        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            guard let self else { return }
            let bpm = Self.extractHeartRate(from: samples)
            Task { @MainActor in self.heartRate = bpm }
        }

        query.updateHandler = { [weak self] _, samples, _, _, _ in
            guard let self else { return }
            let bpm = Self.extractHeartRate(from: samples)
            Task { @MainActor in self.heartRate = bpm }
        }

        store.execute(query)
        heartRateQuery = query
    }

    func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            store.stop(query)
            heartRateQuery = nil
        }
    }

    private nonisolated static func extractHeartRate(from samples: [HKSample]?) -> Double {
        guard let samples = samples as? [HKQuantitySample],
              let latest = samples.last else { return 0 }
        return latest.quantity.doubleValue(for: HKUnit(from: "count/min"))
    }

    // MARK: - Fetch recent workouts

    func fetchRecentWorkouts(limit: Int = 10) async -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            store.execute(query)
        }
    }

    // MARK: - Load today stats

    func loadTodayStats() async {
        async let stepsResult   = fetchTodaySteps()
        async let caloriesResult = fetchTodayCalories()

        let (s, c) = await (stepsResult, caloriesResult)
        steps          = s
        activeCalories = c
    }
}
