//
//  MealPlan.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 03/05/2026.
//


import Foundation
import SwiftData

@Model
final class MealPlan {
    var id: UUID
    var goal: String
    var dailyCalories: Int
    var proteinTargetG: Int
    var carbsTargetG: Int
    var fatTargetG: Int
    var createdAt: Date

    init(
        goal: String,
        dailyCalories: Int,
        proteinTargetG: Int,
        carbsTargetG: Int,
        fatTargetG: Int
    ) {
        self.id             = UUID()
        self.goal           = goal
        self.dailyCalories  = dailyCalories
        self.proteinTargetG = proteinTargetG
        self.carbsTargetG   = carbsTargetG
        self.fatTargetG     = fatTargetG
        self.createdAt      = Date()
    }
}
