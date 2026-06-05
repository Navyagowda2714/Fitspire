//
//  NutritionViewModel.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 03/05/2026.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class NutritionViewModel: ObservableObject {
    @Published var nutritionPlan: DailyNutritionPlan?
    @Published var isLoading: Bool = false
    @Published var selectedMeal: Meal?

    private let engine = NutritionRecommendationEngine()

    func generatePlan(
        goal: FitnessGoal,
        weightKG: Double,
        heightCM: Double,
        age: Int,
        activityLevel: String,
        preferences: [FoodPreference] = []
    ) {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            self.nutritionPlan = self.engine.generate(
                goal: goal,
                weightKG: weightKG,
                heightCM: heightCM,
                age: age,
                activityLevel: activityLevel,
                preferences: preferences
            )
            self.isLoading = false
        }
    }

    func savePlan(context: ModelContext) {
        guard let plan = nutritionPlan else { return }

        let saved = MealPlan(
            goal: plan.goal.rawValue,
            dailyCalories: plan.dailyCalories,
            proteinTargetG: plan.proteinTargetG,
            carbsTargetG: plan.carbsTargetG,
            fatTargetG: plan.fatTargetG
        )
        context.insert(saved)
        try? context.save()
    }

    func meals(ofType type: MealType) -> [Meal] {
        nutritionPlan?.meals.filter { $0.type == type } ?? []
    }

    var proteinProgress: Double {
        guard let plan = nutritionPlan, plan.proteinTargetG > 0 else { return 0 }
        return Double(plan.totalProteinFromMeals) / Double(plan.proteinTargetG)
    }

    var calorieProgress: Double {
        guard let plan = nutritionPlan, plan.dailyCalories > 0 else { return 0 }
        return Double(plan.totalCaloriesFromMeals) / Double(plan.dailyCalories)
    }
}

