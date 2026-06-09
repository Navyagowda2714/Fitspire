//
//  AppState.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 28/04/2026.
//
//


import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated:       Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var hasCompletedBodyScan:  Bool = false
    @Published var hasCompletedProfile:   Bool = false
    @Published var hasCompletedGoal:      Bool = false
    @Published var hasSeenIntro:          Bool = false   // ← NEW
    @Published var hasAcceptedTerms:      Bool = false   // ← NEW (injury/medical disclaimer)
    @Published var selectedGoal:          FitnessGoal?
    @Published var userProfile:           UserProfile?

    init() {
        loadSession()
    }

    func loadSession() {
        isAuthenticated        = UserDefaults.standard.bool(forKey: "isAuthenticated")
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        hasCompletedBodyScan   = UserDefaults.standard.bool(forKey: "hasCompletedBodyScan")
        hasCompletedProfile    = UserDefaults.standard.bool(forKey: "hasCompletedProfile")
        hasCompletedGoal       = UserDefaults.standard.bool(forKey: "hasCompletedGoal")
        hasSeenIntro           = UserDefaults.standard.bool(forKey: "hasSeenIntro")   // ← NEW
        hasAcceptedTerms       = UserDefaults.standard.bool(forKey: "hasAcceptedTerms")   // ← NEW
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

    func markBodyScanComplete() {
        hasCompletedBodyScan = true
        UserDefaults.standard.set(true, forKey: "hasCompletedBodyScan")
    }

    func markProfileComplete() {
        hasCompletedProfile = true
        UserDefaults.standard.set(true, forKey: "hasCompletedProfile")
    }

    func markGoalComplete(goal: FitnessGoal) {
        selectedGoal    = goal
        hasCompletedGoal = true
        UserDefaults.standard.set(goal.rawValue, forKey: "selectedGoal")
        UserDefaults.standard.set(true,          forKey: "hasCompletedGoal")
    }

    func markIntroSeen() {            // ← NEW
        hasSeenIntro = true
        UserDefaults.standard.set(true, forKey: "hasSeenIntro")
    }

    func markTermsAccepted() {        // ← NEW
        hasAcceptedTerms = true
        UserDefaults.standard.set(true, forKey: "hasAcceptedTerms")
    }

    func signOut() {
        isAuthenticated        = false
        hasCompletedOnboarding = false
        hasCompletedBodyScan   = false
        hasCompletedProfile    = false
        hasCompletedGoal       = false
        // hasSeenIntro stays true — don't re-show intro after sign-out
        selectedGoal   = nil
        userProfile    = nil
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "hasCompletedBodyScan")
        UserDefaults.standard.removeObject(forKey: "hasCompletedProfile")
        UserDefaults.standard.removeObject(forKey: "hasCompletedGoal")
        UserDefaults.standard.removeObject(forKey: "selectedGoal")
    }
}
