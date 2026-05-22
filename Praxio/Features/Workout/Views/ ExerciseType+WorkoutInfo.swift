//
//   ExerciseType+WorkoutInfo.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 08/05/2026.
//


//
//   ExerciseType+WorkoutInfo.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 08/05/2026.
//



import Foundation

extension ExerciseType {

    var demoIcon: String {
        switch self {
        case .squat:         return "figure.strengthtraining.traditional"
        case .plank:         return "figure.core.training"
        case .pushUp:        return "figure.highintensity.intervaltraining"
        case .shoulderPress: return "figure.arms.open"
        case .deadlift:      return "figure.strengthtraining.functional"
        case .lunge:           return "figure.walk"
        case .gluteBridge:     return "figure.yoga"
        case .mountainClimber: return "figure.climbing"
        case .highKnees:       return "figure.run"
        case .general:         return "figure.walk"
        }
    }

    var targetMuscles: String {
        switch self {
        case .squat:         return "Quads · Glutes · Hamstrings · Core"
        case .plank:         return "Core · Shoulders · Back"
        case .pushUp:        return "Chest · Triceps · Shoulders · Core"
        case .shoulderPress: return "Shoulders · Triceps · Upper back"
        case .deadlift:      return "Back · Hamstrings · Glutes · Core"
        case .lunge:           return "Quads · Glutes · Hamstrings · Balance"
        case .gluteBridge:     return "Glutes · Hamstrings · Lower Back"
        case .mountainClimber: return "Core · Hip Flexors · Cardio"
        case .highKnees:       return "Hip Flexors · Quads · Cardio"
        case .general:         return "Full body"
        }
    }

    var formPoints: [String] {
        switch self {
        case .squat:
            return [
                "Feet shoulder-width apart, toes slightly out",
                "Keep knees aligned over toes throughout",
                "Chest up, back neutral, core braced",
                "Lower until thighs are parallel to floor"
            ]
        case .plank:
            return [
                "Forearms flat, elbows directly under shoulders",
                "Body forms a straight line from head to heel",
                "Core tight — hips neither sagging nor raised",
                "Hold steady and breathe throughout"
            ]
        case .pushUp:
            return [
                "Hands shoulder-width apart, fingers pointing forward",
                "Elbows at 45 degrees — not flared wide",
                "Body in a straight line from head to heel",
                "Lower until chest nearly touches the floor"
            ]
        case .shoulderPress:
            return [
                "Grip just outside shoulder width",
                "Core braced, lower back neutral — no arch",
                "Press directly overhead, arms fully extended",
                "Lower bar to chin level with control"
            ]
        case .deadlift:
            return [
                "Bar over mid-foot, shoulder-width grip",
                "Hinge at hips — back flat, chest proud",
                "Push the floor away — do not pull with back",
                "Drive hips forward at the top of the lift"
            ]
        case .lunge:
            return [
                "Step back so front shin stays vertical",
                "Lower back knee close to floor without touching",
                "Keep chest up and torso upright",
                "Push through front heel to return"
            ]
        case .gluteBridge:
            return [
                "Feet flat, knees bent at 90°",
                "Press through heels to drive hips up",
                "Squeeze glutes hard at the top",
                "Lower slowly — don't drop hips"
            ]
        case .mountainClimber:
            return [
                "Start in a strong high-plank position",
                "Drive one knee toward chest",
                "Keep hips level throughout",
                "Alternate quickly but stay controlled"
            ]
        case .highKnees:
            return [
                "Drive knees up to hip height each rep",
                "Land on balls of feet — not flat-footed",
                "Arms pump in opposition to legs",
                "Stay tall — don't lean back"
            ]
        case .general:
            return [
                "Move with control — no rushing",
                "Breathe steadily throughout",
                "Stop if you feel any pain or discomfort"
            ]
        }
    }

    var commonMistakes: [String] {
        switch self {
        case .squat:
            return [
                "Knees caving inward during the descent",
                "Heels lifting off the ground",
                "Rounding the lower back at the bottom"
            ]
        case .plank:
            return [
                "Letting hips sag toward the floor",
                "Raising hips too high into a pike",
                "Holding your breath instead of breathing"
            ]
        case .pushUp:
            return [
                "Flaring elbows out to 90 degrees",
                "Hips sagging or raising during the rep",
                "Not achieving full range of motion"
            ]
        case .shoulderPress:
            return [
                "Arching the lower back excessively",
                "Using leg drive to push the bar up",
                "Pressing in front of the body not overhead"
            ]
        case .deadlift:
            return [
                "Rounding the lower back under load",
                "Jerking the bar off the floor",
                "Letting the bar drift away from the body"
            ]
        case .lunge:
            return [
                "Front knee tracking past the toes",
                "Torso leaning too far forward",
                "Back knee slamming the floor"
            ]
        case .gluteBridge:
            return [
                "Using lower back instead of glutes",
                "Feet set too far from body",
                "Knees drifting apart at the top"
            ]
        case .mountainClimber:
            return [
                "Hips rising too high as you fatigue",
                "Bouncing on hands instead of pressing them in",
                "Not driving knee far enough forward"
            ]
        case .highKnees:
            return [
                "Not lifting knees high enough",
                "Landing heavily on heels",
                "Leaning back as pace increases"
            ]
        case .general:
            return [
                "Moving too fast and losing control",
                "Skipping the warm-up",
                "Training through sharp pain"
            ]
        }
    }

    var targetReps: String {
        switch self {
        case .squat:         return "8–12 reps"
        case .plank:         return "30–60 sec"
        case .pushUp:        return "8–15 reps"
        case .shoulderPress: return "8–12 reps"
        case .deadlift:      return "5–8 reps"
        case .lunge:           return "10 each leg"
        case .gluteBridge:     return "15 reps"
        case .mountainClimber: return "30 sec"
        case .highKnees:       return "30 sec"
        case .general:         return "3 sets"
        }
    }

    var restTime: String { "60–90 sec" }

    var difficulty: String {
        switch self {
        case .squat, .pushUp, .plank: return "Beginner"
        case .shoulderPress:          return "Intermediate"
        case .deadlift:               return "Intermediate"
        case .lunge:                  return "Beginner"
        case .gluteBridge:            return "Beginner"
        case .mountainClimber:        return "Intermediate"
        case .highKnees:              return "Beginner"
        case .general:                return "Any level"
        }
    }

    var targetRepCount: Int {
        switch self {
        case .squat, .pushUp, .shoulderPress: return 10
        case .plank:                          return 1
        case .deadlift:                       return 6
        case .lunge:                          return 10
        case .gluteBridge:                    return 15
        case .mountainClimber:                return 1
        case .highKnees:                      return 1
        case .general:                        return 10
        }
    }
}
