//
//  AppState.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var hasCompletedProfile: Bool = false
    @Published var hasCompletedGoal: Bool = false
    @Published var selectedGoal: FitnessGoal?
    @Published var userProfile: UserProfile?

    init() {
        loadSession()
    }

    func loadSession() {
        isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        hasCompletedProfile = UserDefaults.standard.bool(forKey: "hasCompletedProfile")
        hasCompletedGoal = UserDefaults.standard.bool(forKey: "hasCompletedGoal")
        if let raw = UserDefaults.standard.string(forKey: "selectedGoal") {
            selectedGoal = FitnessGoal(rawValue: raw)
        }
    }

    func markAuthenticated() {
        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
    }

    func markOnboardingComplete() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func markProfileComplete() {
        hasCompletedProfile = true
        UserDefaults.standard.set(true, forKey: "hasCompletedProfile")
    }

    func markGoalComplete(goal: FitnessGoal) {
        selectedGoal = goal
        hasCompletedGoal = true
        UserDefaults.standard.set(goal.rawValue, forKey: "selectedGoal")
        UserDefaults.standard.set(true, forKey: "hasCompletedGoal")
    }

    func signOut() {
        isAuthenticated = false
        hasCompletedOnboarding = false
        hasCompletedProfile = false
        hasCompletedGoal = false
        selectedGoal = nil
        userProfile = nil
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "hasCompletedProfile")
        UserDefaults.standard.removeObject(forKey: "hasCompletedGoal")
        UserDefaults.standard.removeObject(forKey: "selectedGoal")
    }
}
