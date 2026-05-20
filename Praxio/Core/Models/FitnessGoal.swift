//
//  FitnessGoal.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation

enum FitnessGoal: String, CaseIterable, Identifiable, Codable {
    case leanBody           = "Lean Body"
    case muscleBuilding     = "Muscle Building"
    case bulking            = "Bulking"
    case tournamentPrep     = "Tournament Preparation"
    case enduranceFitness   = "Endurance Fitness"
    case stayingActive      = "Staying Active"
    case stayingLean        = "Staying Lean"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .leanBody:         return "Strength + cardio, moderate deficit"
        case .muscleBuilding:   return "Hypertrophy, progressive overload"
        case .bulking:          return "Heavy compounds, calorie surplus"
        case .tournamentPrep:   return "Event-specific conditioning"
        case .enduranceFitness: return "Zone 2 cardio, intervals, mobility"
        case .stayingActive:    return "Full body, low intensity, consistent"
        case .stayingLean:      return "Maintenance, balanced macros"
        }
    }

    var weeklyFrequency: ClosedRange<Int> {
        switch self {
        case .leanBody:         return 4...5
        case .muscleBuilding:   return 4...6
        case .bulking:          return 4...6
        case .tournamentPrep:   return 5...6
        case .enduranceFitness: return 3...6
        case .stayingActive:    return 3...4
        case .stayingLean:      return 4...5
        }
    }
}
