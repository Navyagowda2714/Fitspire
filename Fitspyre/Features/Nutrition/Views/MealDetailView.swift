//
//  MealDetailView.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 03/05/2026.
//

//
//  MealDetailView.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 03/05/2026.
//


import SwiftUI

struct MealDetailView: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Macro row
                    HStack(spacing: 10) {
                        MacroCard(value: "\(meal.calories)", label: "kcal", color: "C6FF3D")
                        MacroCard(value: "\(meal.proteinG)g", label: "Protein", color: "1D9E75")
                        MacroCard(value: "\(meal.carbsG)g", label: "Carbs", color: "BA7517")
                        MacroCard(value: "\(meal.fatG)g", label: "Fat", color: "C6FF3D")
                    }
                    .padding(.horizontal, 24)

                    // Prep time
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appT3)
                        Text("\(meal.prepMinutes) minutes prep")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appT3)
                    }
                    .padding(.horizontal, 24)

                    // Description
                    Text(meal.description)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appT3)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)

                    // Ingredients
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ingredients")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.horizontal, 24)

                        VStack(spacing: 0) {
                            ForEach(meal.ingredients, id: \.self) { ingredient in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.appLime)
                                        .frame(width: 6, height: 6)
                                    Text(ingredient)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)

                                if ingredient != meal.ingredients.last {
                                    Divider()
                                        .padding(.leading, 44)
                                }
                            }
                        }
                        .background(Color.appBG)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 24)
                    }

                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.horizontal, 24)

                        Text(meal.instructions)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appT3)
                            .lineSpacing(5)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.appBG2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .navigationTitle(meal.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct MacroCard: View {
    let value: String
    let label: String
    let color: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: color))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.appT3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.appBG2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
