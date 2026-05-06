//
//  ProgressView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 03/05/2026.
//


import SwiftUI
import HealthKit

struct ProgressView: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var recentWorkouts: [HKWorkout] = []
    @State private var hasRequestedPermission = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if !healthKit.isAuthorized {
                        healthKitPrompt
                    } else {
                        statsSection
                        recentWorkoutsSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            healthKit.checkAuthorizationStatus()
            if healthKit.isAuthorized {
                Task { await loadData() }
            }
        }
    }

    // MARK: - HealthKit prompt

    private var healthKitPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(hex: "D85A30"))

            Text("Connect Apple Health")
                .font(.system(size: 20, weight: .medium))

            Text("Allow FitnessAI to read and save your workout data to Apple Health.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task {
                    let granted = await healthKit.requestAuthorization()
                    if granted {
                        await loadData()
                    }
                }
            } label: {
                Text("Connect Apple Health")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "D85A30"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 60)
    }

    // MARK: - Stats section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            HStack(spacing: 12) {
                HealthStatCard(
                    icon: "flame.fill",
                    value: "\(Int(healthKit.activeCalories))",
                    label: "Active kcal",
                    color: "D85A30"
                )
                HealthStatCard(
                    icon: "figure.walk",
                    value: "\(healthKit.steps)",
                    label: "Steps",
                    color: "1D9E75"
                )
                HealthStatCard(
                    icon: "heart.fill",
                    value: healthKit.heartRate > 0
                        ? "\(Int(healthKit.heartRate))"
                        : "--",
                    label: "BPM",
                    color: "D85A30"
                )
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Recent workouts section

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent workouts")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            if recentWorkouts.isEmpty {
                Text("No workouts saved yet. Complete a workout to see it here.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            } else {
                ForEach(recentWorkouts.prefix(5), id: \.uuid) { workout in
                    WorkoutHistoryRow(workout: workout)
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    private func loadData() async {
        await healthKit.loadTodayStats()
        recentWorkouts = await healthKit.fetchRecentWorkouts()
    }
}

// MARK: - Supporting views

struct HealthStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: color))
            Text(value)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.primary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WorkoutHistoryRow: View {
    let workout: HKWorkout

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.startDate)
    }

    var duration: String {
        let minutes = Int(workout.duration / 60)
        return "\(minutes) min"
    }

    var calories: String {
        guard let calType = HKQuantityType.quantityType(
            forIdentifier: .activeEnergyBurned
        ) else { return "-- kcal" }
        let cal = workout.statistics(for: calType)?
            .sumQuantity()?
            .doubleValue(for: .kilocalorie()) ?? 0
        return "\(Int(cal)) kcal"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "EEEDFE"))
                    .frame(width: 44, height: 44)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "534AB7"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(workout.workoutActivityType.name)
                    .font(.system(size: 14, weight: .medium))
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(duration)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.primary)
                Text(calories)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .traditionalStrengthTraining: return "Strength Training"
        case .coreTraining:                return "Core Training"
        case .running:                     return "Running"
        case .cycling:                     return "Cycling"
        case .walking:                     return "Walking"
        case .yoga:                        return "Yoga"
        default:                           return "Workout"
        }
    }
}
