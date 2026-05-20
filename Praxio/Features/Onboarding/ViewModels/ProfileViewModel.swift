//
//  ProfileViewModel.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: String = ""
    @Published var heightCM: String = ""
    @Published var weightKG: String = ""
    @Published var selectedActivity: ActivityLevel = .moderate
    @Published var selectedExperience: ExperienceLevel = .beginner
    @Published var injuries: String = ""
    @Published var likedCuisines: [CuisinePreference] = []
    @Published var dislikedCuisines: [CuisinePreference] = []

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
enum CuisinePreference: String, CaseIterable, Codable {
    // Asian
    case indian        = "Indian"
    case chinese       = "Chinese"
    case japanese      = "Japanese"
    case korean        = "Korean"
    case thai          = "Thai"
    case vietnamese    = "Vietnamese"
    case indonesian    = "Indonesian"
    case filipino      = "Filipino"

    // Western
    case american      = "American"
    case british       = "British"
    case french        = "French"
    case italian       = "Italian"
    case spanish       = "Spanish"
    case greek         = "Greek"
    case german        = "German"
    case mediterranean = "Mediterranean"

    // Middle East & African
    case turkish       = "Turkish"
    case lebanese      = "Lebanese"
    case moroccan      = "Moroccan"
    case ethiopian     = "Ethiopian"
    case egyptian      = "Egyptian"

    // Americas
    case mexican       = "Mexican"
    case brazilian     = "Brazilian"
    case peruvian      = "Peruvian"
    case caribbean     = "Caribbean"

    var region: String {
        switch self {
        case .indian, .chinese, .japanese, .korean,
             .thai, .vietnamese, .indonesian, .filipino:
            return "Asian"
        case .american, .british, .french, .italian,
             .spanish, .greek, .german, .mediterranean:
            return "Western"
        case .turkish, .lebanese, .moroccan, .ethiopian, .egyptian:
            return "Middle East & African"
        case .mexican, .brazilian, .peruvian, .caribbean:
            return "Americas"
        }
    }
}
