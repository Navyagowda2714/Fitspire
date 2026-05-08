//
//  QuestionnaireModels.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 07/05/2026.
//


import Foundation

// MARK: - PAR-Q Safety Screening

struct PARQResult {
    var advisedAgainstExercise: Bool = false
    var chestPainDuringActivity: Bool = false
    var chestPainAtRest: Bool = false
    var dizzinessOrFainting: Bool = false
    var boneOrJointIssue: Bool = false
    var medicationsForHeartOrBP: Bool = false
    var otherReasonNotToExercise: Bool = false

    var isCleared: Bool {
        return !advisedAgainstExercise &&
               !chestPainDuringActivity &&
               !chestPainAtRest &&
               !dizzinessOrFainting &&
               !boneOrJointIssue &&
               !medicationsForHeartOrBP &&
               !otherReasonNotToExercise
    }

    var requiresMedicalClearance: Bool { !isCleared }
}

// MARK: - Fitness Self Tests

struct FitnessSelfTest {
    var maxPushUps: Int = 0
    var plankHoldSeconds: Int = 0
    var mileWalkMinutes: Int = 0
    var didSkipTests: Bool = false

    var pushUpLevel: FitnessTestLevel {
        switch maxPushUps {
        case 0...5:   return .veryLow
        case 6...10:  return .low
        case 11...20: return .moderate
        case 21...30: return .good
        default:      return .excellent
        }
    }

    var plankLevel: FitnessTestLevel {
        switch plankHoldSeconds {
        case 0...15:  return .veryLow
        case 16...30: return .low
        case 31...60: return .moderate
        case 61...120: return .good
        default:      return .excellent
        }
    }
}

enum FitnessTestLevel: String {
    case veryLow   = "Very low"
    case low       = "Low"
    case moderate  = "Moderate"
    case good      = "Good"
    case excellent = "Excellent"
}

// MARK: - Main Goal

enum WorkoutGoal: String, CaseIterable, Codable {
    case loseFat       = "Lose fat"
    case buildStrength = "Build strength"
    case toneUp        = "Tone up"
    case improveHealth = "Improve general health"
    case buildMuscle   = "Build muscle"
    case increaseEnergy = "Increase energy"

    var icon: String {
        switch self {
        case .loseFat:        return "flame.fill"
        case .buildStrength:  return "bolt.fill"
        case .toneUp:         return "figure.strengthtraining.traditional"
        case .improveHealth:  return "heart.fill"
        case .buildMuscle:    return "dumbbell.fill"
        case .increaseEnergy: return "sun.max.fill"
        }
    }

    var description: String {
        switch self {
        case .loseFat:        return "Burn fat, cardio + strength mix"
        case .buildStrength:  return "Get stronger with progressive overload"
        case .toneUp:         return "Lean and defined, moderate reps"
        case .improveHealth:  return "Feel better, move more, live well"
        case .buildMuscle:    return "Muscle hypertrophy, higher volume"
        case .increaseEnergy: return "Daily movement, reduce fatigue"
        }
    }
}

// MARK: - Focus Area

enum FocusArea: String, CaseIterable, Codable {
    case fullBody   = "Full body"
    case upperBody  = "Upper body"
    case lowerBody  = "Lower body"
    case core       = "Core"
    case cardio     = "Cardio"

    var muscles: String {
        switch self {
        case .fullBody:  return "All muscle groups"
        case .upperBody: return "Chest, back, shoulders, arms"
        case .lowerBody: return "Quads, glutes, hamstrings, calves"
        case .core:      return "Abs, obliques, lower back"
        case .cardio:    return "Heart, lungs, endurance"
        }
    }
}

// MARK: - Session Length

enum SessionLength: String, CaseIterable, Codable {
    case short    = "20 minutes"
    case medium   = "30 minutes"
    case standard = "45 minutes"
    case long     = "60 minutes"

    var minutes: Int {
        switch self {
        case .short:    return 20
        case .medium:   return 30
        case .standard: return 45
        case .long:     return 60
        }
    }
}

// MARK: - Training Days

enum TrainingDays: Int, CaseIterable, Codable {
    case three = 3
    case four  = 4
    case five  = 5

    var label: String { "\(rawValue) days per week" }
}

// MARK: - Injury or Limitation

struct HealthCondition: Identifiable, Codable {
    let id = UUID()
    let name: String
    let affectsExercises: [String]
    let avoidMovements: [String]
}

enum CommonCondition: String, CaseIterable {
    case backPain       = "Lower back pain"
    case kneePain       = "Knee pain"
    case shoulderPain   = "Shoulder pain"
    case hipTightness   = "Hip tightness"
    case wristPain      = "Wrist pain"
    case pregnancy      = "Pregnancy"
    case heartCondition = "Heart condition"
    case none           = "None of the above"

    var avoidMovements: [String] {
        switch self {
        case .backPain:
            return ["Deadlifts", "Heavy squats", "Sit-ups"]
        case .kneePain:
            return ["Jump squats", "Deep lunges", "Running"]
        case .shoulderPain:
            return ["Overhead press", "Push-ups on wrists", "Pull-ups"]
        case .hipTightness:
            return ["Deep squats", "High kicks"]
        case .wristPain:
            return ["Push-ups on hands", "Plank on hands"]
        case .pregnancy:
            return ["Crunches", "Lying flat on back", "High impact jumps"]
        case .heartCondition:
            return ["High intensity intervals", "Maximum effort exercises"]
        case .none:
            return []
        }
    }
}

// MARK: - Complete Questionnaire Response

struct QuestionnaireResponse {
    // Basic info
    var name: String = ""
    var age: Int = 25
    var gender: String = "Female"
    var heightCM: Double = 165
    var weightKG: Double = 65
    var location: String = ""

    // PAR-Q
    var parqResult: PARQResult = PARQResult()

    // Health
    var conditions: [CommonCondition] = [.none]
    var otherInjury: String = ""

    // Fitness level
    var experience: ExperienceLevel = .beginner
    var activeDaysPerWeek: Int = 2
    var selfTest: FitnessSelfTest = FitnessSelfTest()
    var motivationLevel: Int = 7

    // Goals
    var primaryGoal: WorkoutGoal = .loseFat
    var focusArea: FocusArea = .fullBody
    var sessionLength: SessionLength = .standard
    var trainingDays: TrainingDays = .three

    // Equipment
    var equipment: [HomeEquipment] = [.noEquipment]
    var spaceAvailableSqFt: Int = 50

    var computedFitnessLevel: ExperienceLevel {
        if selfTest.didSkipTests { return experience }
        let pushScore  = selfTest.pushUpLevel
        let plankScore = selfTest.plankLevel
        if pushScore == .excellent || plankScore == .excellent { return .advanced }
        if pushScore == .good || plankScore == .good { return .intermediate }
        return .beginner
    }

    var hasEquipment: Bool {
        !equipment.isEmpty && !(equipment.count == 1 && equipment.contains(.noEquipment))
    }

    var requiresMedicalClearance: Bool {
        parqResult.requiresMedicalClearance
    }
}
