//
//  ProfileViewModel.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation
import SwiftData

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: String = ""
    @Published var heightCM: String = ""
    @Published var weightKG: String = ""
    @Published var selectedActivity: ActivityLevel = .moderate
    @Published var selectedExperience: ExperienceLevel = .beginner
    @Published var injuries: String = ""

    var isValid: Bool {
        !name.isEmpty &&
        Int(age) != nil &&
        Double(heightCM) != nil &&
        Double(weightKG) != nil
    }

    func saveProfile(context: ModelContext, appState: AppState) {
        guard isValid else { return }

        let profile = UserProfile(
            name: name,
            age: Int(age) ?? 25,
            heightCM: Double(heightCM) ?? 170,
            weightKG: Double(weightKG) ?? 70
        )
        profile.activityLevel = selectedActivity.rawValue
        profile.experienceLevel = selectedExperience.rawValue
        if !injuries.isEmpty {
            profile.injuries = [injuries]
        }

        context.insert(profile)
        appState.userProfile = profile
        appState.markProfileComplete()
    }
}

enum ActivityLevel: String, CaseIterable {
    case sedentary = "Sedentary"
    case light = "Light"
    case moderate = "Moderate"
    case active = "Active"
    case veryActive = "Very active"
}

enum ExperienceLevel: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}
