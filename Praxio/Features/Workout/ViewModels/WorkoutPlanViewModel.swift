//
//  WorkoutPlanViewModel.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class WorkoutPlanViewModel: ObservableObject {
    @Published var generatedPlan: GeneratedWorkoutPlan?
    @Published var isLoading: Bool = false

    private let engine = WorkoutRecommendationEngine()

    func generatePlan(
        goal: FitnessGoal,
        experience: String,
        injuries: [String],
        postureScore: Double
    ) {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }
            self.generatedPlan = self.engine.generate(
                goal: goal,
                experience: experience,
                injuries: injuries,
                postureScore: postureScore
            )
            self.isLoading = false
        }
    }

    func savePlan(context: ModelContext) {
        guard let plan = generatedPlan else { return }

        let saved = WorkoutPlan(
            goal: plan.goal.rawValue,
            splitType: plan.splitType,
            weeklyFrequency: plan.weeklyFrequency,
            timelineMonths: plan.timelineMonths,
            progressionNote: plan.progressionNote
        )
        context.insert(saved)
        try? context.save()
    }
}

