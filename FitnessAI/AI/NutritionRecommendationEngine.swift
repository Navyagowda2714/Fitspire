//
//  NutritionRecommendationEngine.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation

final class NutritionRecommendationEngine {

    func generate(
        goal: FitnessGoal,
        weightKG: Double,
        heightCM: Double,
        age: Int,
        activityLevel: String,
        preferences: [FoodPreference] = []
    ) -> DailyNutritionPlan {

        let calories = calculateCalories(
            goal: goal,
            weightKG: weightKG,
            heightCM: heightCM,
            age: age,
            activityLevel: activityLevel
        )
        let protein  = calculateProtein(goal: goal, weightKG: weightKG)
        let fat      = calculateFat(calories: calories)
        let carbs    = calculateCarbs(
            calories: calories,
            protein: protein,
            fat: fat
        )
        let hydration = calculateHydration(
            weightKG: weightKG,
            activityLevel: activityLevel
        )
        let meals    = generateMeals(goal: goal, preferences: preferences)
        let notes    = generateNotes(goal: goal)

        return DailyNutritionPlan(
            goal: goal,
            dailyCalories: calories,
            proteinTargetG: protein,
            carbsTargetG: carbs,
            fatTargetG: fat,
            hydrationML: hydration,
            meals: meals,
            nutritionNotes: notes
        )
    }

    // MARK: - Calculations

    private func calculateCalories(
        goal: FitnessGoal,
        weightKG: Double,
        heightCM: Double,
        age: Int,
        activityLevel: String
    ) -> Int {
        // Mifflin-St Jeor BMR
        let bmr = 10 * weightKG + 6.25 * heightCM - 5 * Double(age) + 5

        let multiplier: Double
        switch activityLevel.lowercased() {
        case "sedentary":  multiplier = 1.2
        case "light":      multiplier = 1.375
        case "moderate":   multiplier = 1.55
        case "active":     multiplier = 1.725
        case "very active": multiplier = 1.9
        default:           multiplier = 1.55
        }

        let tdee = bmr * multiplier

        switch goal {
        case .muscleBuilding:   return Int(tdee + 300)
        case .bulking:          return Int(tdee + 500)
        case .leanBody:         return Int(tdee - 400)
        case .stayingLean:      return Int(tdee)
        case .enduranceFitness: return Int(tdee + 200)
        case .stayingActive:    return Int(tdee - 100)
        case .tournamentPrep:   return Int(tdee + 100)
        }
    }

    private func calculateProtein(
        goal: FitnessGoal,
        weightKG: Double
    ) -> Int {
        let multiplier: Double
        switch goal {
        case .muscleBuilding:   multiplier = 2.0
        case .bulking:          multiplier = 1.8
        case .leanBody:         multiplier = 2.2
        case .stayingLean:      multiplier = 1.8
        case .enduranceFitness: multiplier = 1.6
        case .stayingActive:    multiplier = 1.4
        case .tournamentPrep:   multiplier = 2.0
        }
        return Int(weightKG * multiplier)
    }

    private func calculateFat(calories: Int) -> Int {
        return Int(Double(calories) * 0.25 / 9)
    }

    private func calculateCarbs(
        calories: Int,
        protein: Int,
        fat: Int
    ) -> Int {
        let proteinCals = protein * 4
        let fatCals     = fat * 9
        let remaining   = calories - proteinCals - fatCals
        return max(0, Int(Double(remaining) / 4))
    }

    private func calculateHydration(
        weightKG: Double,
        activityLevel: String
    ) -> Int {
        let base = weightKG * 35
        let extra: Double
        switch activityLevel.lowercased() {
        case "active", "very active": extra = 500
        case "moderate":              extra = 250
        default:                      extra = 0
        }
        return Int(base + extra)
    }

    // MARK: - Meal generation

    private func generateMeals(
        goal: FitnessGoal,
        preferences: [FoodPreference]
    ) -> [Meal] {
        let isVegetarian = preferences.contains(.vegetarian)
            || preferences.contains(.vegan)

        switch goal {
        case .muscleBuilding: return muscleBuildingMeals(vegetarian: isVegetarian)
        case .bulking:        return bulkingMeals(vegetarian: isVegetarian)
        case .leanBody:       return leanBodyMeals(vegetarian: isVegetarian)
        case .enduranceFitness: return enduranceMeals(vegetarian: isVegetarian)
        case .stayingActive:  return stayingActiveMeals(vegetarian: isVegetarian)
        case .stayingLean:    return stayingLeanMeals(vegetarian: isVegetarian)
        case .tournamentPrep: return tournamentMeals(vegetarian: isVegetarian)
        }
    }

    // MARK: - Muscle Building meals

    private func muscleBuildingMeals(vegetarian: Bool) -> [Meal] {
        return [
            Meal(
                type: .breakfast,
                name: "Protein oats with eggs",
                description: "High protein breakfast to kickstart muscle recovery",
                calories: 520,
                proteinG: 38,
                carbsG: 52,
                fatG: 12,
                prepMinutes: 10,
                ingredients: ["80g oats", "3 whole eggs", "1 banana", "250ml milk", "1 tbsp peanut butter"],
                instructions: "Cook oats with milk. Scramble eggs separately. Slice banana on top. Add peanut butter."
            ),
            Meal(
                type: .lunch,
                name: vegetarian ? "Paneer and rice bowl" : "Chicken and rice bowl",
                description: "Balanced meal with lean protein and complex carbs",
                calories: 680,
                proteinG: 45,
                carbsG: 75,
                fatG: 14,
                prepMinutes: 20,
                ingredients: vegetarian
                    ? ["200g paneer", "150g rice", "mixed vegetables", "2 tbsp olive oil", "spices"]
                    : ["200g chicken breast", "150g rice", "broccoli", "2 tbsp olive oil", "spices"],
                instructions: "Cook rice. Grill protein with spices. Steam vegetables. Combine in bowl."
            ),
            Meal(
                type: .preWorkout,
                name: "Banana and protein shake",
                description: "Fast energy and protein before training",
                calories: 320,
                proteinG: 28,
                carbsG: 42,
                fatG: 4,
                prepMinutes: 3,
                ingredients: ["1 large banana", "1 scoop whey protein", "300ml water or milk"],
                instructions: "Blend all ingredients. Consume 30–45 minutes before training."
            ),
            Meal(
                type: .postWorkout,
                name: "Greek yoghurt with berries",
                description: "Fast protein and carbs for recovery",
                calories: 280,
                proteinG: 22,
                carbsG: 32,
                fatG: 5,
                prepMinutes: 3,
                ingredients: ["200g Greek yoghurt", "100g mixed berries", "1 tbsp honey", "30g granola"],
                instructions: "Layer yoghurt, berries, granola and drizzle honey. Eat within 30 minutes post-workout."
            ),
            Meal(
                type: .dinner,
                name: vegetarian ? "Lentil and sweet potato curry" : "Salmon with sweet potato",
                description: "High protein evening meal with healthy fats",
                calories: 620,
                proteinG: 42,
                carbsG: 58,
                fatG: 18,
                prepMinutes: 25,
                ingredients: vegetarian
                    ? ["200g red lentils", "1 large sweet potato", "coconut milk", "spinach", "curry spices"]
                    : ["200g salmon fillet", "1 large sweet potato", "asparagus", "1 tbsp olive oil", "lemon"],
                instructions: "Roast sweet potato at 200C for 25 min. Cook protein. Serve with vegetables."
            ),
            Meal(
                type: .snack,
                name: "Cottage cheese and rice cakes",
                description: "Slow release protein snack",
                calories: 180,
                proteinG: 18,
                carbsG: 16,
                fatG: 4,
                prepMinutes: 2,
                ingredients: ["150g cottage cheese", "3 rice cakes", "cucumber slices"],
                instructions: "Top rice cakes with cottage cheese. Serve with cucumber."
            )
        ]
    }

    // MARK: - Lean Body meals

    private func leanBodyMeals(vegetarian: Bool) -> [Meal] {
        return [
            Meal(
                type: .breakfast,
                name: "Egg white omelette",
                description: "High protein low calorie breakfast",
                calories: 320,
                proteinG: 28,
                carbsG: 18,
                fatG: 8,
                prepMinutes: 10,
                ingredients: ["4 egg whites", "1 whole egg", "spinach", "mushrooms", "cherry tomatoes"],
                instructions: "Whisk eggs. Cook vegetables in pan. Pour eggs over. Fold and serve."
            ),
            Meal(
                type: .lunch,
                name: vegetarian ? "Quinoa and chickpea salad" : "Tuna and quinoa bowl",
                description: "High fibre filling lunch",
                calories: 480,
                proteinG: 38,
                carbsG: 45,
                fatG: 10,
                prepMinutes: 15,
                ingredients: vegetarian
                    ? ["150g cooked quinoa", "200g chickpeas", "cucumber", "tomatoes", "lemon dressing"]
                    : ["1 tin tuna", "150g quinoa", "mixed leaves", "cucumber", "lemon dressing"],
                instructions: "Cook quinoa. Mix all ingredients. Dress with lemon and olive oil."
            ),
            Meal(
                type: .preWorkout,
                name: "Apple and almond butter",
                description: "Light pre-workout energy",
                calories: 200,
                proteinG: 5,
                carbsG: 28,
                fatG: 9,
                prepMinutes: 2,
                ingredients: ["1 medium apple", "1 tbsp almond butter"],
                instructions: "Slice apple. Serve with almond butter for dipping."
            ),
            Meal(
                type: .postWorkout,
                name: "Protein shake with oats",
                description: "Recovery shake",
                calories: 280,
                proteinG: 28,
                carbsG: 30,
                fatG: 4,
                prepMinutes: 3,
                ingredients: ["1 scoop protein powder", "30g oats", "300ml water", "ice"],
                instructions: "Blend all together. Drink immediately after training."
            ),
            Meal(
                type: .dinner,
                name: vegetarian ? "Tofu stir fry with vegetables" : "Grilled chicken with salad",
                description: "Light high protein dinner",
                calories: 420,
                proteinG: 40,
                carbsG: 25,
                fatG: 16,
                prepMinutes: 20,
                ingredients: vegetarian
                    ? ["200g firm tofu", "mixed vegetables", "soy sauce", "ginger", "garlic", "sesame oil"]
                    : ["200g chicken breast", "mixed leaves", "cherry tomatoes", "avocado", "olive oil"],
                instructions: "Grill or stir fry protein. Combine with vegetables or salad."
            ),
            Meal(
                type: .snack,
                name: "Carrot sticks and hummus",
                description: "High fibre low calorie snack",
                calories: 140,
                proteinG: 6,
                carbsG: 16,
                fatG: 6,
                prepMinutes: 3,
                ingredients: ["2 medium carrots", "4 tbsp hummus"],
                instructions: "Slice carrots into sticks. Serve with hummus."
            )
        ]
    }

    // MARK: - Bulking meals

    private func bulkingMeals(vegetarian: Bool) -> [Meal] {
        return [
            Meal(
                type: .breakfast,
                name: "Mega protein breakfast",
                description: "Calorie dense muscle building breakfast",
                calories: 750,
                proteinG: 52,
                carbsG: 72,
                fatG: 22,
                prepMinutes: 15,
                ingredients: ["4 whole eggs", "100g oats", "2 tbsp peanut butter", "1 banana", "300ml whole milk"],
                instructions: "Cook oats with milk. Scramble eggs. Add peanut butter and banana."
            ),
            Meal(
                type: .lunch,
                name: vegetarian ? "Massive bean and rice bowl" : "Double chicken rice bowl",
                description: "High calorie high protein lunch",
                calories: 920,
                proteinG: 65,
                carbsG: 95,
                fatG: 20,
                prepMinutes: 25,
                ingredients: vegetarian
                    ? ["300g mixed beans", "200g rice", "avocado", "cheese", "sour cream", "salsa"]
                    : ["300g chicken breast", "200g rice", "avocado", "olive oil", "broccoli"],
                instructions: "Cook rice and protein. Combine all. Top with avocado."
            ),
            Meal(
                type: .preWorkout,
                name: "Mass gainer shake",
                description: "High calorie pre-workout fuel",
                calories: 520,
                proteinG: 35,
                carbsG: 68,
                fatG: 10,
                prepMinutes: 5,
                ingredients: ["2 scoops protein", "1 banana", "50g oats", "2 tbsp peanut butter", "350ml milk"],
                instructions: "Blend all ingredients. Drink 45–60 minutes before training."
            ),
            Meal(
                type: .postWorkout,
                name: "Protein and carb recovery",
                description: "Fast recovery meal",
                calories: 480,
                proteinG: 40,
                carbsG: 55,
                fatG: 8,
                prepMinutes: 5,
                ingredients: ["1.5 scoops protein", "2 rice cakes", "1 banana", "honey"],
                instructions: "Mix protein shake. Eat rice cakes with banana and honey immediately after."
            ),
            Meal(
                type: .dinner,
                name: vegetarian ? "Paneer tikka with naan" : "Beef and sweet potato",
                description: "Dense evening meal",
                calories: 820,
                proteinG: 55,
                carbsG: 78,
                fatG: 28,
                prepMinutes: 30,
                ingredients: vegetarian
                    ? ["250g paneer", "2 naan", "onions", "peppers", "yoghurt marinade", "spices"]
                    : ["250g beef mince", "2 large sweet potatoes", "onions", "olive oil", "spices"],
                instructions: "Cook protein with spices. Roast sweet potato. Serve together."
            ),
            Meal(
                type: .snack,
                name: "Nuts and dried fruit mix",
                description: "Calorie dense snack",
                calories: 380,
                proteinG: 12,
                carbsG: 38,
                fatG: 22,
                prepMinutes: 1,
                ingredients: ["40g mixed nuts", "30g dried raisins or dates", "20g dark chocolate chips"],
                instructions: "Mix together. Eat as a mid-morning or evening snack."
            )
        ]
    }

    // MARK: - Simplified plans for remaining goals

    private func enduranceMeals(vegetarian: Bool) -> [Meal] {
        return [
            Meal(type: .breakfast, name: "Porridge with banana", description: "Slow release energy breakfast", calories: 420, proteinG: 14, carbsG: 72, fatG: 8, prepMinutes: 8, ingredients: ["80g oats", "1 banana", "honey", "300ml milk"], instructions: "Cook oats with milk. Top with banana and honey."),
            Meal(type: .lunch, name: vegetarian ? "Pasta with tomato and lentils" : "Pasta with tuna", description: "Carb loading lunch", calories: 580, proteinG: 32, carbsG: 82, fatG: 10, prepMinutes: 20, ingredients: vegetarian ? ["150g pasta", "200g lentils", "tomato sauce", "parmesan"] : ["150g pasta", "1 tin tuna", "tomato sauce", "olive oil"], instructions: "Cook pasta. Heat sauce and protein. Combine."),
            Meal(type: .preWorkout, name: "Banana and energy gel", description: "Quick energy before long sessions", calories: 180, proteinG: 2, carbsG: 42, fatG: 1, prepMinutes: 1, ingredients: ["1 large banana", "1 energy gel (optional)"], instructions: "Eat 30 min before training."),
            Meal(type: .postWorkout, name: "Recovery smoothie", description: "Fast carbs and protein", calories: 340, proteinG: 22, carbsG: 50, fatG: 5, prepMinutes: 5, ingredients: ["1 scoop protein", "1 banana", "250ml orange juice", "50g oats"], instructions: "Blend and drink within 30 minutes of finishing."),
            Meal(type: .dinner, name: vegetarian ? "Vegetable curry and rice" : "Chicken and vegetable stir fry", description: "Balanced recovery dinner", calories: 560, proteinG: 35, carbsG: 65, fatG: 14, prepMinutes: 25, ingredients: ["protein source", "rice or noodles", "mixed vegetables", "olive oil", "spices"], instructions: "Cook protein and vegetables. Serve with rice."),
            Meal(type: .snack, name: "Rice cakes and banana", description: "Mid session fuel", calories: 180, proteinG: 3, carbsG: 38, fatG: 2, prepMinutes: 1, ingredients: ["3 rice cakes", "1 banana"], instructions: "Eat between sessions for energy.")
        ]
    }

    private func stayingActiveMeals(vegetarian: Bool) -> [Meal] {
        return [
            Meal(type: .breakfast, name: "Whole grain toast and eggs", description: "Balanced start to the day", calories: 380, proteinG: 22, carbsG: 38, fatG: 14, prepMinutes: 10, ingredients: ["2 slices whole grain bread", "2 eggs", "avocado", "tomatoes"], instructions: "Toast bread. Cook eggs your way. Serve with avocado."),
            Meal(type: .lunch, name: vegetarian ? "Veggie wrap" : "Chicken wrap", description: "Easy balanced lunch", calories: 480, proteinG: 28, carbsG: 48, fatG: 16, prepMinutes: 10, ingredients: ["1 large wrap", "protein filling", "salad leaves", "hummus", "tomatoes"], instructions: "Fill wrap with all ingredients. Roll and eat."),
            Meal(type: .preWorkout, name: "Small banana and yoghurt", description: "Light pre-workout snack", calories: 160, proteinG: 8, carbsG: 28, fatG: 2, prepMinutes: 2, ingredients: ["1 small banana", "100g low fat yoghurt"], instructions: "Eat 30 minutes before exercise."),
            Meal(type: .postWorkout, name: "Chocolate milk", description: "Simple recovery drink", calories: 220, proteinG: 8, carbsG: 32, fatG: 5, prepMinutes: 1, ingredients: ["300ml semi-skimmed milk", "2 tsp cocoa powder", "1 tsp honey"], instructions: "Mix and drink after exercise."),
            Meal(type: .dinner, name: vegetarian ? "Bean soup with bread" : "Fish and vegetables", description: "Light nutritious dinner", calories: 460, proteinG: 30, carbsG: 45, fatG: 14, prepMinutes: 20, ingredients: ["protein source", "vegetables", "olive oil", "herbs", "side portion"], instructions: "Cook simply with olive oil and herbs."),
            Meal(type: .snack, name: "Mixed fruit and nuts", description: "Healthy snack", calories: 200, proteinG: 5, carbsG: 24, fatG: 10, prepMinutes: 1, ingredients: ["small handful mixed nuts", "1 piece of fruit"], instructions: "Eat as a mid-morning or afternoon snack.")
        ]
    }

    private func stayingLeanMeals(vegetarian: Bool) -> [Meal] {
        return leanBodyMeals(vegetarian: vegetarian)
    }

    private func tournamentMeals(vegetarian: Bool) -> [Meal] {
        return enduranceMeals(vegetarian: vegetarian)
    }

    // MARK: - Notes

    private func generateNotes(goal: FitnessGoal) -> [String] {
        switch goal {
        case .muscleBuilding:
            return [
                "Eat protein within 30 minutes of finishing your workout.",
                "Space meals 3–4 hours apart for optimal muscle protein synthesis.",
                "Aim for 7–9 hours sleep — most muscle repair happens overnight."
            ]
        case .bulking:
            return [
                "Track calories daily — a surplus of 300–500 kcal is the sweet spot.",
                "Do not skip meals. Consistency is key for muscle gain.",
                "Prioritise whole foods over processed supplements where possible."
            ]
        case .leanBody:
            return [
                "Keep a mild calorie deficit — never drop below 1,400 kcal.",
                "High protein intake preserves muscle while in a deficit.",
                "Drink 2–3 litres of water daily to support fat metabolism."
            ]
        case .enduranceFitness:
            return [
                "Carbohydrates are your primary fuel — do not cut them.",
                "Eat a small carb-rich snack before sessions longer than 60 minutes.",
                "Refuel within 30 minutes after long sessions."
            ]
        case .stayingActive:
            return [
                "Focus on consistency rather than perfection.",
                "Eat a balanced diet with plenty of vegetables and whole grains.",
                "Stay hydrated throughout the day."
            ]
        case .stayingLean:
            return [
                "Eat at maintenance — not a deficit.",
                "Weigh yourself weekly, not daily, to track trends.",
                "Regular strength training preserves muscle mass."
            ]
        case .tournamentPrep:
            return [
                "Increase carbohydrates 2–3 days before competition.",
                "Avoid trying new foods on competition day.",
                "Stay well hydrated in the days leading up to your event."
            ]
        }
    }
}

