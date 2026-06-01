//
//  NutritionModels.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 03/05/2026.
//


import Foundation

enum MealType: String, CaseIterable, Codable {
    case breakfast    = "Breakfast"
    case lunch        = "Lunch"
    case dinner       = "Dinner"
    case preWorkout   = "Pre-workout"
    case postWorkout  = "Post-workout"
    case snack        = "Snack"
}

enum FoodPreference: String, CaseIterable, Codable {
    case vegetarian   = "Vegetarian"
    case vegan        = "Vegan"
    case nonVeg       = "Non-vegetarian"
    case highProtein  = "High protein"
    case glutenFree   = "Gluten-free"
    case dairyFree    = "Dairy-free"
}

struct Meal: Identifiable {
    let id = UUID()
    let type: MealType
    let name: String
    let description: String
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let prepMinutes: Int
    let ingredients: [String]
    let instructions: String
}

struct DailyNutritionPlan: Identifiable {
    let id = UUID()
    let goal: FitnessGoal
    let dailyCalories: Int
    let proteinTargetG: Int
    let carbsTargetG: Int
    let fatTargetG: Int
    let hydrationML: Int
    let meals: [Meal]
    let nutritionNotes: [String]
    let createdAt: Date

    init(
        goal: FitnessGoal,
        dailyCalories: Int,
        proteinTargetG: Int,
        carbsTargetG: Int,
        fatTargetG: Int,
        hydrationML: Int,
        meals: [Meal],
        nutritionNotes: [String] = []
    ) {
        self.goal             = goal
        self.dailyCalories    = dailyCalories
        self.proteinTargetG   = proteinTargetG
        self.carbsTargetG     = carbsTargetG
        self.fatTargetG       = fatTargetG
        self.hydrationML      = hydrationML
        self.meals            = meals
        self.nutritionNotes   = nutritionNotes
        self.createdAt        = Date()
    }

    var totalCaloriesFromMeals: Int {
        meals.reduce(0) { $0 + $1.calories }
    }

    var totalProteinFromMeals: Int {
        meals.reduce(0) { $0 + $1.proteinG }
    }
}
