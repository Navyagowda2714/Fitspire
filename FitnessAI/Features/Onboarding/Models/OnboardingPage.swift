//
//  OnboardingPage.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation

struct OnboardingPage: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let description: String
    let bullets: [String]
}

extension OnboardingPage {
    static let all: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "figure.strengthtraining.traditional",
            title: "Welcome to FitnessAI",
            description: "Your personal AI fitness coach that adapts to your body, goals, and progress.",
            bullets: [
                "Personalised workout plans",
                "Real-time form coaching",
                "Goal-based nutrition plans"
            ]
        ),
        OnboardingPage(
            systemImage: "camera.viewfinder",
            title: "Real-time form coaching",
            description: "FitnessAI uses your camera to detect body pose and give instant feedback.",
            bullets: [
                "Detects 19 body landmarks",
                "Calculates joint angles live",
                "Camera stays on-device only"
            ]
        ),
        OnboardingPage(
            systemImage: "applewatch",
            title: "Apple Watch alerts",
            description: "When unsafe form is detected, your Apple Watch receives an instant haptic alert.",
            bullets: [
                "Haptic feedback on bad form",
                "Correction message on wrist",
                "Works mid-rep in real time"
            ]
        ),
        OnboardingPage(
            systemImage: "heart.text.square",
            title: "HealthKit integration",
            description: "FitnessAI reads and writes to Apple Health to track your fitness journey.",
            bullets: [
                "Saves workout sessions",
                "Tracks calories and heart rate",
                "You control what is shared"
            ]
        ),
        OnboardingPage(
            systemImage: "lock.shield",
            title: "Privacy first",
            description: "Your data belongs to you. Everything runs on-device where possible.",
            bullets: [
                "No video ever leaves your phone",
                "Delete your data anytime",
                "Cloud sync is fully optional"
            ]
        )
    ]
}
