//
//  SettingsViewModel.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 06/05/2026.
//

import Foundation
import SwiftData
import UserNotifications
import Combine
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool = false
    @Published var cloudSyncEnabled: Bool = false
    @Published var isExporting: Bool = false
    @Published var isDeleting: Bool = false
    @Published var exportURL: URL?
    @Published var showDeleteConfirm: Bool = false
    @Published var showExportSuccess: Bool = false
    @Published var errorMessage: String?

    init() {
        loadSettings()
    }

    private func loadSettings() {
        cloudSyncEnabled = UserDefaults.standard.bool(forKey: "cloudSyncEnabled")
        checkNotificationStatus()
    }

    func checkNotificationStatus() {
        UNUserNotificationCenter.current()
            .getNotificationSettings { settings in
                Task { @MainActor in
                    self.notificationsEnabled =
                        settings.authorizationStatus == .authorized
                }
            }
    }

    func toggleCloudSync() {
        cloudSyncEnabled.toggle()
        UserDefaults.standard.set(
            cloudSyncEnabled,
            forKey: "cloudSyncEnabled"
        )
    }

    func openNotificationSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else { return }
        UIApplication.shared.open(url)
    }

    func openHealthSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Export data

    func exportData(context: ModelContext) async {
        isExporting = true

        do {
            let profiles  = try context.fetch(FetchDescriptor<UserProfile>())
            let scanResults = try context.fetch(
                FetchDescriptor<BodyScanResult>()
            )
            let mealPlans = try context.fetch(FetchDescriptor<MealPlan>())
            let workoutPlans = try context.fetch(
                FetchDescriptor<WorkoutPlan>()
            )

            var exportData: [String: Any] = [:]

            if let profile = profiles.first {
                exportData["profile"] = [
                    "name":            profile.name,
                    "age":             profile.age,
                    "heightCM":        profile.heightCM,
                    "weightKG":        profile.weightKG,
                    "goal":            profile.goal,
                    "activityLevel":   profile.activityLevel,
                    "experienceLevel": profile.experienceLevel,
                    "createdAt":       profile.createdAt.ISO8601Format()
                ]
            }

            exportData["bodyScanResults"] = scanResults.map { scan in
                [
                    "postureScore":  scan.postureScore,
                    "symmetryScore": scan.symmetryScore,
                    "mobilityScore": scan.mobilityScore,
                    "date":          scan.createdAt.ISO8601Format()
                ]
            }

            exportData["mealPlans"] = mealPlans.map { plan in
                [
                    "goal":           plan.goal,
                    "dailyCalories":  plan.dailyCalories,
                    "proteinTargetG": plan.proteinTargetG,
                    "date":           plan.createdAt.ISO8601Format()
                ]
            }

            exportData["workoutPlans"] = workoutPlans.map { plan in
                [
                    "goal":           plan.goal,
                    "splitType":      plan.splitType,
                    "weeklyFreq":     plan.weeklyFrequency,
                    "timelineMonths": plan.timelineMonths,
                    "date":           plan.createdAt.ISO8601Format()
                ]
            }

            exportData["exportedAt"] = Date().ISO8601Format()
            exportData["appVersion"] = "1.0.0"

            let jsonData = try JSONSerialization.data(
                withJSONObject: exportData,
                options: .prettyPrinted
            )

            let filename = "Fitspyre_export_\(Date().ISO8601Format()).json"
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(filename)

            try jsonData.write(to: url)
            exportURL = url
            showExportSuccess = true

        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }

        isExporting = false
    }

    // MARK: - Delete all data

    func deleteAllData(
        context: ModelContext,
        appState: AppState
    ) async {
        isDeleting = true

        do {
            try context.delete(model: UserProfile.self)
            try context.delete(model: BodyScanResult.self)
            try context.delete(model: MealPlan.self)
            try context.delete(model: WorkoutPlan.self)
            try context.save()
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }

        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier ?? ""
        )

        isDeleting = false
        appState.signOut()
    }
}
