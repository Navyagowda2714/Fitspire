//
//  NutritionView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 03/05/2026.
//

//
//  NutritionView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 03/05/2026.
//


import SwiftUI
import SwiftData

struct NutritionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = NutritionViewModel()
    @State private var selectedMeal: Meal?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let plan = viewModel.nutritionPlan {
                    planView(plan: plan)
                } else {
                    generateView
                }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if viewModel.nutritionPlan == nil {
                loadPlan()
            }
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailView(meal: meal)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(Color.appLime)
            Text("Building your meal plan...")
                .font(.system(size: 14))
                .foregroundStyle(Color.appT3)
        }
    }

    private var generateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 52))
                .foregroundStyle(Color.appLime)
            Text("No meal plan yet")
                .font(.system(size: 18, weight: .medium))
            Text("We will generate one based on your goal and profile.")
                .font(.system(size: 14))
                .foregroundStyle(Color.appT3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                loadPlan()
            } label: {
                Text("Generate my plan")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 48)
                    .background(Color.appLime)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func planView(plan: DailyNutritionPlan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Goal and calories header
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.goal.rawValue)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appT3)
                    Text("\(plan.dailyCalories) kcal / day")
                        .font(.system(size: 28, weight: .medium))
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Macro targets
                HStack(spacing: 10) {
                    MacroCard(
                        value: "\(plan.proteinTargetG)g",
                        label: "Protein",
                        color: "1D9E75"
                    )
                    MacroCard(
                        value: "\(plan.carbsTargetG)g",
                        label: "Carbs",
                        color: "BA7517"
                    )
                    MacroCard(
                        value: "\(plan.fatTargetG)g",
                        label: "Fat",
                        color: "C6FF3D"
                    )
                    MacroCard(
                        value: "\(plan.hydrationML / 1000)L",
                        label: "Water",
                        color: "378ADD"
                    )
                }
                .padding(.horizontal, 24)

                // Meals
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's meals")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.appT3)
                        .padding(.horizontal, 24)

                    ForEach(MealType.allCases, id: \.self) { type in
                        let mealsOfType = plan.meals.filter { $0.type == type }
                        ForEach(mealsOfType) { meal in
                            MealRow(meal: meal) {
                                selectedMeal = meal
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }

                // Nutrition notes
                if !plan.nutritionNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Nutrition tips")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.appT3)
                            .padding(.horizontal, 24)

                        ForEach(plan.nutritionNotes, id: \.self) { note in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.appWarn)
                                    .padding(.top, 1)
                                Text(note)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.appT3)
                                    .lineSpacing(3)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
    }

    private func loadPlan() {
        guard let goal = appState.selectedGoal else { return }
        let profile = appState.userProfile
        viewModel.generatePlan(
            goal: goal,
            weightKG: profile?.weightKG ?? 70,
            heightCM: profile?.heightCM ?? 170,
            age: profile?.age ?? 25,
            activityLevel: profile?.activityLevel ?? "moderate"
        )
    }
}

struct MealRow: View {
    let meal: Meal
    let onTap: () -> Void

    var mealTypeColor: String {
        switch meal.type {
        case .breakfast:   return "BA7517"
        case .lunch:       return "1D9E75"
        case .dinner:      return "534AB7"
        case .preWorkout:  return "D85A30"
        case .postWorkout: return "1D9E75"
        case .snack:       return "888780"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: mealTypeColor).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(String(meal.type.rawValue.prefix(1)))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: mealTypeColor))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(meal.type.rawValue)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appT3)
                    Text(meal.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(meal.calories) kcal")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.appLime)
                    Text("\(meal.proteinG)g protein")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appT3)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appT3)
            }
            .padding(14)
            .background(Color.appBG)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
