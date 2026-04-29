//
//  SwiftDataModels.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//


import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var age: Int
    var heightCM: Double
    var weightKG: Double
    var activityLevel: String
    var experienceLevel: String
    var goal: String
    var injuries: [String]
    var foodPreferences: [String]
    var createdAt: Date

    init(
        name: String,
        age: Int,
        heightCM: Double,
        weightKG: Double
    ) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.heightCM = heightCM
        self.weightKG = weightKG
        self.activityLevel = "moderate"
        self.experienceLevel = "beginner"
        self.goal = FitnessGoal.stayingActive.rawValue
        self.injuries = []
        self.foodPreferences = []
        self.createdAt = Date()
    }
}
